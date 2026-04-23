<?php
// api/models/TransactionCaisseModel.php

require_once __DIR__ . '/BaseModel.php';

class TransactionCaisseModel extends BaseModel {
    protected string $table = 'transactions_caisse';

    public function findByNumeroRecu(string $numero): ?array {
        $stmt = $this->db->prepare(
            "SELECT tc.*, sc.caisse_id, sc.date_session,
                    CONCAT(u.nom, ' ', u.prenom) AS caissier_nom
             FROM transactions_caisse tc
             JOIN sessions_caisse sc ON sc.id = tc.session_id
             JOIN users u ON u.id = sc.caissier_id
             WHERE tc.numero_recu = ?
             LIMIT 1"
        );
        $stmt->execute([$numero]);
        return $stmt->fetch() ?: null;
    }

    public function getAllPaginated(int $page = 1, int $perPage = 20, array $filters = []): array {
        $offset = ($page - 1) * $perPage;
        $where  = ['1=1'];
        $params = [];

        if (!empty($filters['session_id'])) {
            $where[]  = 'tc.session_id = ?';
            $params[] = (int)$filters['session_id'];
        }
        if (!empty($filters['type'])) {
            $where[]  = 'tc.type = ?';
            $params[] = $filters['type'];
        }
        if (!empty($filters['mode_paiement'])) {
            $where[]  = 'tc.mode_paiement = ?';
            $params[] = $filters['mode_paiement'];
        }
        if (!empty($filters['date_debut'])) {
            $where[]  = 'DATE(tc.created_at) >= ?';
            $params[] = $filters['date_debut'];
        }
        if (!empty($filters['date_fin'])) {
            $where[]  = 'DATE(tc.created_at) <= ?';
            $params[] = $filters['date_fin'];
        }

        $whereClause = implode(' AND ', $where);

        $stmtC = $this->db->prepare("SELECT COUNT(*) FROM transactions_caisse tc WHERE {$whereClause}");
        $stmtC->execute($params);
        $total = (int)$stmtC->fetchColumn();

        $sql = "SELECT tc.*, sc.date_session, c.nom AS caisse_nom
                FROM transactions_caisse tc
                JOIN sessions_caisse sc ON sc.id = tc.session_id
                JOIN caisses c ON c.id = sc.caisse_id
                WHERE {$whereClause}
                ORDER BY tc.created_at DESC
                LIMIT ? OFFSET ?";

        $params[] = $perPage;
        $params[] = $offset;

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);

        return ['data' => $stmt->fetchAll(), 'total' => $total];
    }

    public function generateNumeroRecu(): string {
        $prefix = 'REC-' . date('Ymd') . '-';
        $stmt   = $this->db->prepare(
            "SELECT COUNT(*) FROM transactions_caisse WHERE numero_recu LIKE ?"
        );
        $stmt->execute([$prefix . '%']);
        $count = (int)$stmt->fetchColumn() + 1;
        return $prefix . str_pad((string)$count, 4, '0', STR_PAD_LEFT);
    }
}