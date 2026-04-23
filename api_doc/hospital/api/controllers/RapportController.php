<?php
// api/controllers/RapportController.php

require_once __DIR__ . '/../config/Database.php';
require_once __DIR__ . '/../helpers/ResponseHelper.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../middleware/RoleMiddleware.php';

class RapportController {
    private MySQLiConnection $db;

    public function __construct() {
        $this->db = Database::getInstance();
    }

    /** GET /api/rapports/dashboard */
    public function dashboard(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'rapports.read');

        $exerciceId = $_GET['exercice_id'] ?? null;

        // Total recettes (écritures CREDIT validées)
        $sqlRecettes = "SELECT COALESCE(SUM(l.credit), 0) AS total
                        FROM lignes_ecriture l
                        JOIN ecritures_comptables e ON e.id = l.ecriture_id
                        JOIN plan_comptable pc ON pc.id = l.compte_id
                        WHERE e.statut = 'VALIDE'
                          AND pc.type_compte = 'PRODUIT'
                          " . ($exerciceId ? "AND e.exercice_id = {$exerciceId}" : "") . "
                          AND YEAR(e.date_ecriture) = YEAR(CURDATE())";

        $recettes = (float)$this->db->query($sqlRecettes)->fetchColumn();

        // Total dépenses
        $sqlDepenses = "SELECT COALESCE(SUM(l.debit), 0) AS total
                        FROM lignes_ecriture l
                        JOIN ecritures_comptables e ON e.id = l.ecriture_id
                        JOIN plan_comptable pc ON pc.id = l.compte_id
                        WHERE e.statut = 'VALIDE'
                          AND pc.type_compte = 'CHARGE'
                          " . ($exerciceId ? "AND e.exercice_id = {$exerciceId}" : "") . "
                          AND YEAR(e.date_ecriture) = YEAR(CURDATE())";

        $depenses = (float)$this->db->query($sqlDepenses)->fetchColumn();

        // Solde caisse total
        $soldeCaisse = (float)$this->db->query(
            "SELECT COALESCE(SUM(solde_actuel), 0) FROM caisses WHERE is_active = 1"
        )->fetchColumn();

        // Solde banque total
        $soldeBanque = (float)$this->db->query(
            "SELECT COALESCE(SUM(solde_actuel), 0) FROM comptes_bancaires WHERE is_active = 1"
        )->fetchColumn();

        // Écritures en attente de validation
        $ecrituresPendantes = (int)$this->db->query(
            "SELECT COUNT(*) FROM ecritures_comptables WHERE statut = 'SOUMIS'"
        )->fetchColumn();

        // Budget vs Réel (top 5 services)
        $sqlBudget = "SELECT s.nom AS service, b.montant_prevu,
                             COALESCE(SUM(l.debit), 0) AS reel
                      FROM budgets b
                      JOIN services s ON s.id = b.service_id
                      LEFT JOIN ecritures_comptables e ON e.exercice_id = b.exercice_id
                      LEFT JOIN lignes_ecriture l ON l.ecriture_id = e.id
                        AND l.compte_id = b.compte_id
                      WHERE b.statut = 'APPROUVE'
                      GROUP BY b.id, s.nom, b.montant_prevu
                      ORDER BY b.montant_prevu DESC
                      LIMIT 5";
        $budgets = $this->db->query($sqlBudget)->fetchAll();

        // Évolution mensuelle (12 derniers mois)
        $sqlMensuel = "SELECT DATE_FORMAT(e.date_ecriture, '%Y-%m') AS mois,
                              COALESCE(SUM(CASE WHEN pc.type_compte = 'PRODUIT' THEN l.credit ELSE 0 END), 0) AS recettes,
                              COALESCE(SUM(CASE WHEN pc.type_compte = 'CHARGE' THEN l.debit ELSE 0 END), 0) AS depenses
                       FROM ecritures_comptables e
                       JOIN lignes_ecriture l ON l.ecriture_id = e.id
                       JOIN plan_comptable pc ON pc.id = l.compte_id
                       WHERE e.statut = 'VALIDE'
                         AND e.date_ecriture >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
                       GROUP BY DATE_FORMAT(e.date_ecriture, '%Y-%m')
                       ORDER BY mois ASC";
        $mensuel = $this->db->query($sqlMensuel)->fetchAll();

        // Stock en alerte
        $stockAlerte = (int)$this->db->query(
            "SELECT COUNT(*) FROM produits WHERE stock_actuel <= stock_minimum AND is_active = 1"
        )->fetchColumn();

        ResponseHelper::success([
            'financier' => [
                'recettes'           => $recettes,
                'depenses'           => $depenses,
                'resultat_net'       => $recettes - $depenses,
                'solde_caisse'       => $soldeCaisse,
                'solde_banque'       => $soldeBanque,
                'tresorerie_totale'  => $soldeCaisse + $soldeBanque,
            ],
            'alertes' => [
                'ecritures_pendantes' => $ecrituresPendantes,
                'stock_en_alerte'     => $stockAlerte,
            ],
            'budget_vs_reel' => $budgets,
            'evolution_mensuelle' => $mensuel,
        ], 'Tableau de bord');
    }

    /** GET /api/rapports/grand-livre */
    public function grandLivre(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'rapports.read');

        $compteId  = $_GET['compte_id'] ?? null;
        $dateDebut = $_GET['date_debut'] ?? date('Y-01-01');
        $dateFin   = $_GET['date_fin'] ?? date('Y-12-31');

        if (!$compteId) {
            ResponseHelper::error('Le compte est requis', 400);
        }

        $sql = "SELECT e.date_ecriture, e.numero_piece, e.libelle AS ecriture_libelle,
                       j.code AS journal_code, l.libelle AS ligne_libelle,
                       l.debit, l.credit, l.devise
                FROM lignes_ecriture l
                JOIN ecritures_comptables e ON e.id = l.ecriture_id
                JOIN journaux j ON j.id = e.journal_id
                WHERE l.compte_id = ?
                  AND e.statut = 'VALIDE'
                  AND e.date_ecriture BETWEEN ? AND ?
                ORDER BY e.date_ecriture ASC, e.id ASC";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([$compteId, $dateDebut, $dateFin]);
        $lignes = $stmt->fetchAll();

        $totalDebit  = array_sum(array_column($lignes, 'debit'));
        $totalCredit = array_sum(array_column($lignes, 'credit'));
        $solde       = $totalDebit - $totalCredit;

        // Informations du compte
        $sqlCompte = "SELECT * FROM plan_comptable WHERE id = ?";
        $stmtC     = $this->db->prepare($sqlCompte);
        $stmtC->execute([$compteId]);
        $compte = $stmtC->fetch();

        ResponseHelper::success([
            'compte'       => $compte,
            'periode'      => ['debut' => $dateDebut, 'fin' => $dateFin],
            'lignes'       => $lignes,
            'totaux' => [
                'debit'  => $totalDebit,
                'credit' => $totalCredit,
                'solde'  => $solde,
            ]
        ], 'Grand Livre');
    }

    /** GET /api/rapports/balance */
    public function balance(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'rapports.read');

        $exerciceId = $_GET['exercice_id'] ?? null;
        $dateDebut  = $_GET['date_debut'] ?? date('Y-01-01');
        $dateFin    = $_GET['date_fin'] ?? date('Y-12-31');

        $whereEx = $exerciceId ? "AND e.exercice_id = {$exerciceId}" : "";

        $sql = "SELECT pc.numero_compte, pc.libelle, pc.classe, pc.type_compte,
                       COALESCE(SUM(l.debit), 0)  AS total_debit,
                       COALESCE(SUM(l.credit), 0) AS total_credit,
                       COALESCE(SUM(l.debit), 0) - COALESCE(SUM(l.credit), 0) AS solde
                FROM plan_comptable pc
                LEFT JOIN lignes_ecriture l ON l.compte_id = pc.id
                LEFT JOIN ecritures_comptables e ON e.id = l.ecriture_id
                    AND e.statut = 'VALIDE'
                    AND e.date_ecriture BETWEEN ? AND ?
                    {$whereEx}
                WHERE pc.is_active = 1
                GROUP BY pc.id, pc.numero_compte, pc.libelle, pc.classe, pc.type_compte
                HAVING total_debit > 0 OR total_credit > 0
                ORDER BY pc.numero_compte ASC";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([$dateDebut, $dateFin]);
        $balance = $stmt->fetchAll();

        ResponseHelper::success([
            'periode' => ['debut' => $dateDebut, 'fin' => $dateFin],
            'comptes' => $balance,
            'totaux'  => [
                'debit'  => array_sum(array_column($balance, 'total_debit')),
                'credit' => array_sum(array_column($balance, 'total_credit')),
            ]
        ], 'Balance générale');
    }
}