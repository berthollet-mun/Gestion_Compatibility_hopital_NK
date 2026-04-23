<?php
// api/models/CompteBancaireModel.php

require_once __DIR__ . '/BaseModel.php';

class CompteBancaireModel extends BaseModel {
    protected string $table = 'comptes_bancaires';

    public function findAllActive(): array {
        $sql = "SELECT cb.*, pc.numero_compte, pc.libelle AS compte_plan_libelle
                FROM comptes_bancaires cb
                JOIN plan_comptable pc ON pc.id = cb.compte_plan_id
                WHERE cb.is_active = 1
                ORDER BY cb.nom_banque";
        return $this->query($sql);
    }

    public function findWithMouvements(int $id, int $page = 1, int $perPage = 20): array {
        $compte = $this->findById($id);
        if (!$compte) return [];

        $offset = ($page - 1) * $perPage;
        $sql    = "SELECT mb.*
                   FROM mouvements_bancaires mb
                   WHERE mb.compte_bancaire_id = ?
                   ORDER BY mb.date_operation DESC, mb.id DESC
                   LIMIT ? OFFSET ?";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([$id, $perPage, $offset]);
        $compte['mouvements'] = $stmt->fetchAll();

        $stmtC = $this->db->prepare(
            "SELECT COUNT(*) FROM mouvements_bancaires WHERE compte_bancaire_id = ?"
        );
        $stmtC->execute([$id]);
        $compte['total_mouvements'] = (int)$stmtC->fetchColumn();

        return $compte;
    }

    public function updateSolde(int $id, float $delta): bool {
        return $this->execute(
            "UPDATE comptes_bancaires SET solde_actuel = solde_actuel + ? WHERE id = ?",
            [$delta, $id]
        );
    }

    public function getMouvementsNonRapproches(int $id): array {
        $stmt = $this->db->prepare(
            "SELECT * FROM mouvements_bancaires
             WHERE compte_bancaire_id = ? AND is_rapproche = 0
             ORDER BY date_operation"
        );
        $stmt->execute([$id]);
        return $stmt->fetchAll();
    }

    public function getTotalSoldes(): array {
        $sql = "SELECT
                    SUM(CASE WHEN devise = 'CDF' THEN solde_actuel ELSE 0 END) AS total_cdf,
                    SUM(CASE WHEN devise = 'USD' THEN solde_actuel ELSE 0 END) AS total_usd,
                    COUNT(*) AS nb_comptes
                FROM comptes_bancaires WHERE is_active = 1";
        return $this->query($sql)[0] ?? [];
    }
}