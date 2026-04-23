<?php
// api/models/MouvementStockModel.php

require_once __DIR__ . '/BaseModel.php';

class MouvementStockModel extends BaseModel {
    protected string $table = 'mouvements_stock';

    public function getAllPaginated(int $page = 1, int $perPage = 20, array $filters = []): array {
        $offset = ($page - 1) * $perPage;
        $where  = ['1=1'];
        $params = [];

        if (!empty($filters['produit_id'])) {
            $where[]  = 'ms.produit_id = ?';
            $params[] = (int)$filters['produit_id'];
        }
        if (!empty($filters['type'])) {
            $where[]  = 'ms.type = ?';
            $params[] = $filters['type'];
        }
        if (!empty($filters['date_debut'])) {
            $where[]  = 'ms.date_mouvement >= ?';
            $params[] = $filters['date_debut'];
        }
        if (!empty($filters['date_fin'])) {
            $where[]  = 'ms.date_mouvement <= ?';
            $params[] = $filters['date_fin'];
        }

        $whereClause = implode(' AND ', $where);

        $stmtC = $this->db->prepare("SELECT COUNT(*) FROM mouvements_stock ms WHERE {$whereClause}");
        $stmtC->execute($params);
        $total = (int)$stmtC->fetchColumn();

        $sql = "SELECT ms.*, p.code AS produit_code, p.designation AS produit_designation,
                       p.unite_mesure,
                       CONCAT(u.nom, ' ', u.prenom) AS enregistre_par_nom
                FROM mouvements_stock ms
                JOIN produits p ON p.id = ms.produit_id
                JOIN users u ON u.id = ms.enregistre_par
                WHERE {$whereClause}
                ORDER BY ms.date_mouvement DESC, ms.id DESC
                LIMIT ? OFFSET ?";

        $params[] = $perPage;
        $params[] = $offset;

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);

        return ['data' => $stmt->fetchAll(), 'total' => $total];
    }

    public function creerMouvement(array $data, int $userId): int {
        $db = $this->db;
        $db->beginTransaction();

        try {
            // Récupérer stock avant
            $stmtP = $db->prepare("SELECT stock_actuel FROM produits WHERE id = ? FOR UPDATE");
            $stmtP->execute([$data['produit_id']]);
            $produit = $stmtP->fetch();

            if (!$produit) throw new RuntimeException('Produit introuvable');

            $stockAvant = (float)$produit['stock_actuel'];
            $quantite   = (float)$data['quantite'];

            if ($data['type'] === 'SORTIE' && $stockAvant < $quantite) {
                throw new RuntimeException("Stock insuffisant. Disponible: {$stockAvant}");
            }

            $delta     = in_array($data['type'], ['ENTREE']) ? $quantite : -$quantite;
            $stockApres = $stockAvant + $delta;

            // Insérer mouvement
            $sql = "INSERT INTO mouvements_stock
                        (produit_id, type, motif, quantite, prix_unitaire,
                         stock_avant, stock_apres, date_mouvement, date_peremption,
                         numero_lot, ecriture_id, enregistre_par)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

            $stmt = $db->prepare($sql);
            $stmt->execute([
                $data['produit_id'],
                $data['type'],
                $data['motif'],
                $quantite,
                $data['prix_unitaire'] ?? null,
                $stockAvant,
                $stockApres,
                $data['date_mouvement'] ?? date('Y-m-d'),
                $data['date_peremption'] ?? null,
                $data['numero_lot'] ?? null,
                $data['ecriture_id'] ?? null,
                $userId,
            ]);

            $mouvementId = (int)$db->lastInsertId();

            // Mettre à jour stock produit
            $db->prepare("UPDATE produits SET stock_actuel = ? WHERE id = ?")
               ->execute([$stockApres, $data['produit_id']]);

            $db->commit();
            return $mouvementId;

        } catch (Exception $e) {
            $db->rollBack();
            throw $e;
        }
    }

    public function getValeurStock(): array {
        $sql = "SELECT
                    cp.type AS categorie_type,
                    COUNT(p.id) AS nb_produits,
                    SUM(p.stock_actuel) AS total_quantite,
                    SUM(p.stock_actuel * COALESCE(p.prix_unitaire, 0)) AS valeur_totale
                FROM produits p
                JOIN categories_produits cp ON cp.id = p.categorie_id
                WHERE p.is_active = 1
                GROUP BY cp.type";
        return $this->query($sql);
    }
}