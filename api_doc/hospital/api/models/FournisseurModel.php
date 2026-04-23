<?php
// api/models/FournisseurModel.php

require_once __DIR__ . '/BaseModel.php';

class FournisseurModel extends BaseModel {
    protected string $table = 'fournisseurs';

    public function getAllPaginated(int $page = 1, int $perPage = 20, array $filters = []): array {
        $offset = ($page - 1) * $perPage;
        $where  = ['f.is_active = 1'];
        $params = [];

        if (!empty($filters['search'])) {
            $where[]  = '(f.nom LIKE ? OR f.numero_rccm LIKE ? OR f.telephone LIKE ?)';
            $s        = '%' . $filters['search'] . '%';
            $params[] = $s;
            $params[] = $s;
            $params[] = $s;
        }

        $whereClause = implode(' AND ', $where);

        $stmtC = $this->db->prepare("SELECT COUNT(*) FROM fournisseurs f WHERE {$whereClause}");
        $stmtC->execute($params);
        $total = (int)$stmtC->fetchColumn();

        $sql = "SELECT f.*,
                       (SELECT COUNT(*) FROM factures fa WHERE fa.fournisseur_id = f.id) AS nb_factures,
                       (SELECT COALESCE(SUM(fa.montant_ttc), 0) FROM factures fa WHERE fa.fournisseur_id = f.id AND fa.statut != 'ANNULEE') AS total_achats
                FROM fournisseurs f
                WHERE {$whereClause}
                ORDER BY f.nom ASC
                LIMIT ? OFFSET ?";

        $params[] = $perPage;
        $params[] = $offset;

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);

        return ['data' => $stmt->fetchAll(), 'total' => $total];
    }

    public function findWithFactures(int $id, int $page = 1): array {
        $fournisseur = $this->findById($id);
        if (!$fournisseur) return [];

        $offset = ($page - 1) * 10;
        $stmt   = $this->db->prepare(
            "SELECT * FROM factures WHERE fournisseur_id = ?
             ORDER BY date_facture DESC LIMIT 10 OFFSET ?"
        );
        $stmt->execute([$id, $offset]);
        $fournisseur['factures'] = $stmt->fetchAll();

        // Stats
        $sqlStats = "SELECT
                        COUNT(*) AS nb_factures,
                        COALESCE(SUM(montant_ttc), 0) AS total_ttc,
                        COALESCE(SUM(montant_paye), 0) AS total_paye,
                        COALESCE(SUM(montant_ttc - montant_paye), 0) AS total_restant
                     FROM factures WHERE fournisseur_id = ? AND statut != 'ANNULEE'";
        $stmtS = $this->db->prepare($sqlStats);
        $stmtS->execute([$id]);
        $fournisseur['statistiques'] = $stmtS->fetch();

        return $fournisseur;
    }
}