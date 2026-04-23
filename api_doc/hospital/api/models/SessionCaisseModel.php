<?php
// api/models/SessionCaisseModel.php

require_once __DIR__ . '/BaseModel.php';

class SessionCaisseModel extends BaseModel {
    protected string $table = 'sessions_caisse';

    public function findWithDetails(int $id): ?array {
        $sql = "SELECT sc.*,
                       c.nom AS caisse_nom, c.devise,
                       CONCAT(u.nom, ' ', u.prenom) AS caissier_nom
                FROM sessions_caisse sc
                JOIN caisses c ON c.id = sc.caisse_id
                JOIN users u ON u.id = sc.caissier_id
                WHERE sc.id = ?";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$id]);
        return $stmt->fetch() ?: null;
    }

    public function getAllPaginated(int $page = 1, int $perPage = 20, array $filters = []): array {
        $offset = ($page - 1) * $perPage;
        $where  = ['1=1'];
        $params = [];

        if (!empty($filters['caisse_id'])) {
            $where[]  = 'sc.caisse_id = ?';
            $params[] = (int)$filters['caisse_id'];
        }
        if (!empty($filters['caissier_id'])) {
            $where[]  = 'sc.caissier_id = ?';
            $params[] = (int)$filters['caissier_id'];
        }
        if (!empty($filters['date'])) {
            $where[]  = 'sc.date_session = ?';
            $params[] = $filters['date'];
        }
        if (!empty($filters['statut'])) {
            $where[]  = 'sc.statut = ?';
            $params[] = $filters['statut'];
        }

        $whereClause = implode(' AND ', $where);

        $stmtC = $this->db->prepare("SELECT COUNT(*) FROM sessions_caisse sc WHERE {$whereClause}");
        $stmtC->execute($params);
        $total = (int)$stmtC->fetchColumn();

        $sql = "SELECT sc.*, c.nom AS caisse_nom,
                       CONCAT(u.nom, ' ', u.prenom) AS caissier_nom,
                       (SELECT COUNT(*) FROM transactions_caisse t WHERE t.session_id = sc.id) AS nb_transactions,
                       (SELECT COALESCE(SUM(t.montant), 0) FROM transactions_caisse t WHERE t.session_id = sc.id AND t.type = 'ENTREE') AS total_entrees,
                       (SELECT COALESCE(SUM(t.montant), 0) FROM transactions_caisse t WHERE t.session_id = sc.id AND t.type = 'SORTIE') AS total_sorties
                FROM sessions_caisse sc
                JOIN caisses c ON c.id = sc.caisse_id
                JOIN users u ON u.id = sc.caissier_id
                WHERE {$whereClause}
                ORDER BY sc.date_session DESC, sc.id DESC
                LIMIT ? OFFSET ?";

        $params[] = $perPage;
        $params[] = $offset;

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);

        return ['data' => $stmt->fetchAll(), 'total' => $total];
    }
}