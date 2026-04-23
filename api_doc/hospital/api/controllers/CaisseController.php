<?php
// api/controllers/CaisseController.php

require_once __DIR__ . '/../config/Database.php';
require_once __DIR__ . '/../helpers/ResponseHelper.php';
require_once __DIR__ . '/../helpers/AuditHelper.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../middleware/RoleMiddleware.php';
require_once __DIR__ . '/../middleware/ValidationMiddleware.php';

class CaisseController {
    private MySQLiConnection $db;

    public function __construct() {
        $this->db = Database::getInstance();
    }

    /** GET /api/caisse/sessions */
    public function getSessions(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'caisse.read');

        $page   = (int)($_GET['page'] ?? 1);
        $offset = ($page - 1) * 20;

        $sql = "SELECT sc.*, c.nom AS caisse_nom,
                       CONCAT(u.nom, ' ', u.prenom) AS caissier_nom
                FROM sessions_caisse sc
                JOIN caisses c ON c.id = sc.caisse_id
                JOIN users u ON u.id = sc.caissier_id
                ORDER BY sc.date_session DESC, sc.id DESC
                LIMIT 20 OFFSET ?";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([$offset]);

        ResponseHelper::success($stmt->fetchAll(), 'Sessions de caisse');
    }

    /** POST /api/caisse/ouvrir */
    public function ouvrirSession(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'caisse.create');

        $data = ValidationMiddleware::getJsonBody();
        ValidationMiddleware::make($data)
            ->required('caisse_id', 'Caisse')
            ->required('solde_ouverture', 'Solde d\'ouverture')
            ->numeric('solde_ouverture')
            ->validated();

        // Vérifier si session déjà ouverte aujourd'hui
        $checkSql = "SELECT id FROM sessions_caisse
                     WHERE caisse_id = ? AND date_session = CURDATE() AND statut = 'OUVERTE'";
        $checkStmt = $this->db->prepare($checkSql);
        $checkStmt->execute([$data['caisse_id']]);

        if ($checkStmt->fetch()) {
            ResponseHelper::error('Une session est déjà ouverte pour cette caisse aujourd\'hui', 400);
        }

        $sql = "INSERT INTO sessions_caisse
                    (caisse_id, caissier_id, date_session, solde_ouverture, statut)
                VALUES (?, ?, CURDATE(), ?, 'OUVERTE')";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            $data['caisse_id'],
            $user['id'],
            (float)$data['solde_ouverture']
        ]);

        $sessionId = $this->db->lastInsertId();
        AuditHelper::log($user['id'], 'OUVRIR_CAISSE', 'sessions_caisse', (int)$sessionId);
        ResponseHelper::success(['session_id' => $sessionId], 'Caisse ouverte avec succès', 201);
    }

    /** POST /api/caisse/transactions */
    public function addTransaction(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'caisse.create');

        $data = ValidationMiddleware::getJsonBody();
        ValidationMiddleware::make($data)
            ->required('session_id', 'Session')
            ->required('type', 'Type')
            ->required('motif', 'Motif')
            ->required('montant', 'Montant')
            ->inArray('type', ['ENTREE', 'SORTIE'])
            ->numeric('montant')
            ->positive('montant')
            ->validated();

        // Vérifier la session
        $sessionSql  = "SELECT sc.*, c.solde_actuel FROM sessions_caisse sc
                        JOIN caisses c ON c.id = sc.caisse_id
                        WHERE sc.id = ? AND sc.statut = 'OUVERTE'";
        $sessionStmt = $this->db->prepare($sessionSql);
        $sessionStmt->execute([$data['session_id']]);
        $session = $sessionStmt->fetch();

        if (!$session) {
            ResponseHelper::error('Session de caisse introuvable ou fermée', 400);
        }

        $montant = (float)$data['montant'];

        // Vérifier solde suffisant pour sortie
        if ($data['type'] === 'SORTIE' && $session['solde_actuel'] < $montant) {
            ResponseHelper::error('Solde insuffisant en caisse', 400);
        }

        // Générer numéro de reçu unique
        $numRecu = 'REC-' . date('Ymd') . '-' . str_pad((string)rand(1, 9999), 4, '0', STR_PAD_LEFT);

        $sql = "INSERT INTO transactions_caisse
                    (session_id, numero_recu, type, motif, beneficiaire,
                     montant, mode_paiement, reference_paiement, observation)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            $data['session_id'],
            $numRecu,
            $data['type'],
            $data['motif'],
            $data['beneficiaire'] ?? null,
            $montant,
            $data['mode_paiement'] ?? 'ESPECES',
            $data['reference_paiement'] ?? null,
            $data['observation'] ?? null,
        ]);

        $transId = $this->db->lastInsertId();

        // Mettre à jour le solde de la caisse
        $delta = $data['type'] === 'ENTREE' ? $montant : -$montant;
        $this->db->prepare(
            "UPDATE caisses SET solde_actuel = solde_actuel + ? WHERE id = ?"
        )->execute([$delta, $session['caisse_id']]);

        AuditHelper::log($user['id'], 'TRANSACTION_CAISSE', 'transactions_caisse', (int)$transId, null, $data);
        ResponseHelper::success(
            ['transaction_id' => $transId, 'numero_recu' => $numRecu],
            'Transaction enregistrée',
            201
        );
    }

    /** PUT /api/caisse/sessions/{id}/fermer */
    public function fermerSession(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'caisse.close');

        $data = ValidationMiddleware::getJsonBody();
        ValidationMiddleware::make($data)
            ->required('solde_fermeture', 'Solde de fermeture')
            ->numeric('solde_fermeture')
            ->validated();

        $sql  = "SELECT * FROM sessions_caisse WHERE id = ? AND statut = 'OUVERTE'";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$id]);
        $session = $stmt->fetch();

        if (!$session) {
            ResponseHelper::error('Session introuvable ou déjà fermée', 400);
        }

        $this->db->prepare(
            "UPDATE sessions_caisse
             SET statut = 'FERMEE', solde_fermeture = ?, heure_fermeture = NOW()
             WHERE id = ?"
        )->execute([(float)$data['solde_fermeture'], $id]);

        AuditHelper::log($user['id'], 'FERMER_CAISSE', 'sessions_caisse', $id);
        ResponseHelper::success(null, 'Caisse fermée avec succès');
    }

    /** GET /api/caisse/sessions/{id}/rapport */
    public function rapportSession(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'caisse.read');

        $sqlSession = "SELECT sc.*, c.nom AS caisse_nom,
                              CONCAT(u.nom, ' ', u.prenom) AS caissier_nom
                       FROM sessions_caisse sc
                       JOIN caisses c ON c.id = sc.caisse_id
                       JOIN users u ON u.id = sc.caissier_id
                       WHERE sc.id = ?";
        $stmtS = $this->db->prepare($sqlSession);
        $stmtS->execute([$id]);
        $session = $stmtS->fetch();

        if (!$session) ResponseHelper::error('Session introuvable', 404);

        $sqlTrans = "SELECT * FROM transactions_caisse WHERE session_id = ? ORDER BY created_at";
        $stmtT    = $this->db->prepare($sqlTrans);
        $stmtT->execute([$id]);
        $transactions = $stmtT->fetchAll();

        $totalEntrees = array_sum(
            array_column(array_filter($transactions, fn($t) => $t['type'] === 'ENTREE'), 'montant')
        );
        $totalSorties = array_sum(
            array_column(array_filter($transactions, fn($t) => $t['type'] === 'SORTIE'), 'montant')
        );

        ResponseHelper::success([
            'session'       => $session,
            'transactions'  => $transactions,
            'resume' => [
                'total_entrees'  => $totalEntrees,
                'total_sorties'  => $totalSorties,
                'solde_theorique'=> $session['solde_ouverture'] + $totalEntrees - $totalSorties,
                'ecart'          => $session['solde_fermeture']
                                    ? ($session['solde_fermeture'] - ($session['solde_ouverture'] + $totalEntrees - $totalSorties))
                                    : null,
            ]
        ], 'Rapport de caisse');
    }
}