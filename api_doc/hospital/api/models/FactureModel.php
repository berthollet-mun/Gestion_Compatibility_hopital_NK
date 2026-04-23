<?php
// api/models/FactureModel.php

require_once __DIR__ . '/BaseModel.php';

class FactureModel extends BaseModel {
    protected string $table = 'factures';

    public function getAllPaginated(int $page = 1, int $perPage = 20, array $filters = []): array {
        $offset = ($page - 1) * $perPage;
        $where  = ['1=1'];
        $params = [];

        if (!empty($filters['type'])) {
            $where[]  = 'f.type = ?';
            $params[] = $filters['type'];
        }
        if (!empty($filters['statut'])) {
            $where[]  = 'f.statut = ?';
            $params[] = $filters['statut'];
        }
        if (!empty($filters['fournisseur_id'])) {
            $where[]  = 'f.fournisseur_id = ?';
            $params[] = (int)$filters['fournisseur_id'];
        }
        if (!empty($filters['date_debut'])) {
            $where[]  = 'f.date_facture >= ?';
            $params[] = $filters['date_debut'];
        }
        if (!empty($filters['date_fin'])) {
            $where[]  = 'f.date_facture <= ?';
            $params[] = $filters['date_fin'];
        }

        $whereClause = implode(' AND ', $where);

        $stmtC = $this->db->prepare("SELECT COUNT(*) FROM factures f WHERE {$whereClause}");
        $stmtC->execute($params);
        $total = (int)$stmtC->fetchColumn();

        $sql = "SELECT f.*,
                       fo.nom AS fournisseur_nom,
                       CONCAT(u.nom, ' ', u.prenom) AS cree_par_nom,
                       (f.montant_ttc - f.montant_paye) AS montant_restant
                FROM factures f
                LEFT JOIN fournisseurs fo ON fo.id = f.fournisseur_id
                JOIN users u ON u.id = f.cree_par
                WHERE {$whereClause}
                ORDER BY f.date_facture DESC, f.id DESC
                LIMIT ? OFFSET ?";

        $params[] = $perPage;
        $params[] = $offset;

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);

        return ['data' => $stmt->fetchAll(), 'total' => $total];
    }

    public function findWithLignes(int $id): ?array {
        $facture = $this->findById($id);
        if (!$facture) return null;

        $sql = "SELECT lf.*,
                       ta.code_acte, ta.designation AS acte_designation,
                       p.code AS produit_code, p.designation AS produit_designation,
                       (lf.quantite * lf.prix_unitaire * (1 - lf.remise_pct/100)) AS montant_ht
                FROM lignes_facture lf
                LEFT JOIN tarifs_actes ta ON ta.id = lf.tarif_acte_id
                LEFT JOIN produits p ON p.id = lf.produit_id
                WHERE lf.facture_id = ?";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$id]);
        $facture['lignes'] = $stmt->fetchAll();

        return $facture;
    }

    public function generateNumero(string $type): string {
        $prefix = match($type) {
            'CLIENT'      => 'FC',
            'FOURNISSEUR' => 'FF',
            'AVOIR'       => 'AV',
            default       => 'FA',
        };

        $year  = date('Y');
        $stmt  = $this->db->prepare(
            "SELECT COUNT(*) FROM factures WHERE type = ? AND YEAR(date_facture) = ?"
        );
        $stmt->execute([$type, $year]);
        $count = (int)$stmt->fetchColumn() + 1;

        return "{$prefix}-{$year}-" . str_pad((string)$count, 5, '0', STR_PAD_LEFT);
    }

    public function enregistrerPaiement(int $id, float $montant): array {
        $facture = $this->findById($id);
        if (!$facture) throw new RuntimeException('Facture introuvable');

        $restant = (float)$facture['montant_ttc'] - (float)$facture['montant_paye'];
        if ($montant > $restant + 0.01) {
            throw new RuntimeException("Montant dépasse le solde restant ({$restant})");
        }

        $nouvPaye   = (float)$facture['montant_paye'] + $montant;
        $nouveauStat = ($nouvPaye >= (float)$facture['montant_ttc'] - 0.01)
                       ? 'PAYEE' : 'PARTIELLEMENT_PAYEE';

        $this->update($id, [
            'montant_paye' => $nouvPaye,
            'statut'       => $nouveauStat,
        ]);

        return ['statut' => $nouveauStat, 'montant_paye' => $nouvPaye, 'restant' => $restant - $montant];
    }

    public function getFacturesEchues(): array {
        $sql = "SELECT f.*,
                       fo.nom AS fournisseur_nom,
                       DATEDIFF(CURDATE(), f.date_echeance) AS jours_retard
                FROM factures f
                LEFT JOIN fournisseurs fo ON fo.id = f.fournisseur_id
                WHERE f.date_echeance < CURDATE()
                  AND f.statut IN ('EMISE', 'PARTIELLEMENT_PAYEE')
                ORDER BY jours_retard DESC";
        return $this->query($sql);
    }
}