<?php
// api/models/BudgetModel.php

require_once __DIR__ . '/BaseModel.php';

class BudgetModel extends BaseModel {
    protected string $table = 'budgets';

    public function getAllPaginated(int $page = 1, int $perPage = 20, array $filters = []): array {
        $offset = ($page - 1) * $perPage;
        $where  = ['1=1'];
        $params = [];

        if (!empty($filters['exercice_id'])) {
            $where[]  = 'b.exercice_id = ?';
            $params[] = (int)$filters['exercice_id'];
        }
        if (!empty($filters['service_id'])) {
            $where[]  = 'b.service_id = ?';
            $params[] = (int)$filters['service_id'];
        }
        if (!empty($filters['statut'])) {
            $where[]  = 'b.statut = ?';
            $params[] = $filters['statut'];
        }

        $whereClause = implode(' AND ', $where);

        $stmtC = $this->db->prepare("SELECT COUNT(*) FROM budgets b WHERE {$whereClause}");
        $stmtC->execute($params);
        $total = (int)$stmtC->fetchColumn();

        $sql = "SELECT b.*,
                       s.nom AS service_nom,
                       pc.numero_compte, pc.libelle AS compte_libelle,
                       ef.annee AS exercice_annee,
                       CONCAT(us.nom, ' ', us.prenom) AS soumis_par_nom,
                       CONCAT(ua.nom, ' ', ua.prenom) AS approuve_par_nom,
                       COALESCE((
                           SELECT SUM(l.debit)
                           FROM lignes_ecriture l
                           JOIN ecritures_comptables e ON e.id = l.ecriture_id
                           WHERE l.compte_id = b.compte_id
                             AND e.exercice_id = b.exercice_id
                             AND e.statut = 'VALIDE'
                       ), 0) AS montant_realise
                FROM budgets b
                JOIN services s ON s.id = b.service_id
                JOIN plan_comptable pc ON pc.id = b.compte_id
                JOIN exercices_fiscaux ef ON ef.id = b.exercice_id
                JOIN users us ON us.id = b.soumis_par
                LEFT JOIN users ua ON ua.id = b.approuve_par
                WHERE {$whereClause}
                ORDER BY b.created_at DESC
                LIMIT ? OFFSET ?";

        $params[] = $perPage;
        $params[] = $offset;

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);

        return ['data' => $stmt->fetchAll(), 'total' => $total];
    }

    public function findWithDetails(int $id): ?array {
        $sql = "SELECT b.*,
                       s.nom AS service_nom,
                       pc.numero_compte, pc.libelle AS compte_libelle,
                       ef.annee AS exercice_annee,
                       CONCAT(us.nom, ' ', us.prenom) AS soumis_par_nom,
                       CONCAT(ua.nom, ' ', ua.prenom) AS approuve_par_nom
                FROM budgets b
                JOIN services s ON s.id = b.service_id
                JOIN plan_comptable pc ON pc.id = b.compte_id
                JOIN exercices_fiscaux ef ON ef.id = b.exercice_id
                JOIN users us ON us.id = b.soumis_par
                LEFT JOIN users ua ON ua.id = b.approuve_par
                WHERE b.id = ?";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$id]);
        return $stmt->fetch() ?: null;
    }

    public function getTauxExecution(int $exerciceId, int $serviceId): array {
        $sql = "SELECT
                    SUM(b.montant_prevu) AS total_prevu,
                    COALESCE(SUM(
                        (SELECT SUM(l.debit)
                         FROM lignes_ecriture l
                         JOIN ecritures_comptables e ON e.id = l.ecriture_id
                         WHERE l.compte_id = b.compte_id
                           AND e.exercice_id = b.exercice_id
                           AND e.statut = 'VALIDE')
                    ), 0) AS total_realise
                FROM budgets b
                WHERE b.exercice_id = ?
                  AND b.service_id = ?
                  AND b.statut = 'APPROUVE'";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$exerciceId, $serviceId]);
        $result = $stmt->fetch();

        $prevu   = (float)($result['total_prevu'] ?? 0);
        $realise = (float)($result['total_realise'] ?? 0);
        $taux    = $prevu > 0 ? round(($realise / $prevu) * 100, 2) : 0;

        return [
            'total_prevu'   => $prevu,
            'total_realise' => $realise,
            'ecart'         => $prevu - $realise,
            'taux_execution'=> $taux,
        ];
    }
}