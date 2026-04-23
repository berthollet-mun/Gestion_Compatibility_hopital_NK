<?php
// api/models/MouvementBancaireModel.php

require_once __DIR__ . '/BaseModel.php';

class MouvementBancaireModel extends BaseModel {
    protected string $table = 'mouvements_bancaires';

    public function getAllPaginated(int $compteBancaireId, int $page = 1, int $perPage = 20, array $filters = []): array {
        $offset = ($page - 1) * $perPage;
        $where  = ['mb.compte_bancaire_id = ?'];
        $params = [$compteBancaireId];

        if (!empty($filters['type'])) {
            $where[]  = 'mb.type = ?';
            $params[] = $filters['type'];
        }
        if (!empty($filters['is_rapproche'])) {
            $where[]  = 'mb.is_rapproche = ?';
            $params[] = (int)$filters['is_rapproche'];
        }
        if (!empty($filters['date_debut'])) {
            $where[]  = 'mb.date_operation >= ?';
            $params[] = $filters['date_debut'];
        }
        if (!empty($filters['date_fin'])) {
            $where[]  = 'mb.date_operation <= ?';
            $params[] = $filters['date_fin'];
        }

        $whereClause = implode(' AND ', $where);

        $stmtC = $this->db->prepare("SELECT COUNT(*) FROM mouvements_bancaires mb WHERE {$whereClause}");
        $stmtC->execute($params);
        $total = (int)$stmtC->fetchColumn();

        $sql = "SELECT mb.*,
                       e.numero_piece AS ecriture_piece
                FROM mouvements_bancaires mb
                LEFT JOIN ecritures_comptables e ON e.id = mb.ecriture_id
                WHERE {$whereClause}
                ORDER BY mb.date_operation DESC, mb.id DESC
                LIMIT ? OFFSET ?";

        $params[] = $perPage;
        $params[] = $offset;

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);

        return ['data' => $stmt->fetchAll(), 'total' => $total];
    }

    public function rapprocher(array $ids): int {
        $placeholders = implode(',', array_fill(0, count($ids), '?'));
        $sql = "UPDATE mouvements_bancaires
                SET is_rapproche = 1, rapproche_le = NOW()
                WHERE id IN ({$placeholders})";
        $stmt = $this->db->prepare($sql);
        $stmt->execute($ids);
        return $stmt->rowCount();
    }

    public function getResumeParPeriode(int $compteId, string $dateDebut, string $dateFin): array {
        $sql = "SELECT
                    COUNT(*) AS nb_mouvements,
                    COALESCE(SUM(CASE WHEN type = 'CREDIT' THEN montant ELSE 0 END), 0) AS total_entrees,
                    COALESCE(SUM(CASE WHEN type = 'DEBIT' THEN montant ELSE 0 END), 0) AS total_sorties
                FROM mouvements_bancaires
                WHERE compte_bancaire_id = ?
                  AND date_operation BETWEEN ? AND ?";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$compteId, $dateDebut, $dateFin]);
        return $stmt->fetch();
    }
}