<?php
// api/models/ProduitModel.php

require_once __DIR__ . '/BaseModel.php';

class ProduitModel extends BaseModel {
    protected string $table = 'produits';

    public function getAllPaginated(int $page = 1, int $perPage = 20, array $filters = []): array {
        $offset = ($page - 1) * $perPage;
        $where  = ['p.is_active = 1'];
        $params = [];

        if (!empty($filters['categorie_id'])) {
            $where[]  = 'p.categorie_id = ?';
            $params[] = (int)$filters['categorie_id'];
        }
        if (!empty($filters['search'])) {
            $where[]  = '(p.code LIKE ? OR p.designation LIKE ?)';
            $s        = '%' . $filters['search'] . '%';
            $params[] = $s;
            $params[] = $s;
        }
        if (isset($filters['stock_alerte']) && $filters['stock_alerte']) {
            $where[] = 'p.stock_actuel <= p.stock_minimum';
        }

        $whereClause = implode(' AND ', $where);

        $stmtC = $this->db->prepare("SELECT COUNT(*) FROM produits p WHERE {$whereClause}");
        $stmtC->execute($params);
        $total = (int)$stmtC->fetchColumn();

        $sql = "SELECT p.*, cp.nom AS categorie_nom, cp.type AS categorie_type,
                       CASE WHEN p.stock_actuel <= p.stock_minimum THEN 1 ELSE 0 END AS en_alerte
                FROM produits p
                JOIN categories_produits cp ON cp.id = p.categorie_id
                WHERE {$whereClause}
                ORDER BY p.designation ASC
                LIMIT ? OFFSET ?";

        $params[] = $perPage;
        $params[] = $offset;

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);

        return ['data' => $stmt->fetchAll(), 'total' => $total];
    }

    public function findByCode(string $code): ?array {
        $stmt = $this->db->prepare(
            "SELECT p.*, cp.nom AS categorie_nom
             FROM produits p JOIN categories_produits cp ON cp.id = p.categorie_id
             WHERE p.code = ? LIMIT 1"
        );
        $stmt->execute([$code]);
        return $stmt->fetch() ?: null;
    }

    public function getProduitsEnAlerte(): array {
        $sql = "SELECT p.*, cp.nom AS categorie_nom,
                       (p.stock_minimum - p.stock_actuel) AS deficit
                FROM produits p
                JOIN categories_produits cp ON cp.id = p.categorie_id
                WHERE p.stock_actuel <= p.stock_minimum AND p.is_active = 1
                ORDER BY deficit DESC";
        return $this->query($sql);
    }

    public function updateStock(int $id, float $quantite, string $type): bool {
        $operator = ($type === 'ENTREE') ? '+' : '-';
        return $this->execute(
            "UPDATE produits SET stock_actuel = stock_actuel {$operator} ? WHERE id = ?",
            [$quantite, $id]
        );
    }

    public function findWithHistorique(int $id, int $limit = 20): ?array {
        $produit = $this->findById($id);
        if (!$produit) return null;

        $sql = "SELECT ms.*, CONCAT(u.nom, ' ', u.prenom) AS enregistre_par_nom
                FROM mouvements_stock ms
                JOIN users u ON u.id = ms.enregistre_par
                WHERE ms.produit_id = ?
                ORDER BY ms.date_mouvement DESC, ms.id DESC
                LIMIT ?";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$id, $limit]);
        $produit['historique'] = $stmt->fetchAll();

        return $produit;
    }
}