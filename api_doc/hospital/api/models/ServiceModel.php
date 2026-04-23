<?php
// api/models/ServiceModel.php

require_once __DIR__ . '/BaseModel.php';

class ServiceModel extends BaseModel {
    protected string $table = 'services';

    public function findAllActive(): array {
        return $this->query(
            "SELECT s.*, CONCAT(u.nom, ' ', u.prenom) AS responsable_nom
             FROM services s
             LEFT JOIN users u ON u.id = s.responsable_id
             WHERE s.is_active = 1
             ORDER BY s.nom ASC"
        );
    }

    public function findWithStats(int $id): ?array {
        $sql = "SELECT s.*,
                       CONCAT(u.nom, ' ', u.prenom) AS responsable_nom,
                       (SELECT COUNT(*) FROM employes e WHERE e.service_id = s.id AND e.statut = 'ACTIF') AS nb_employes,
                       (SELECT COUNT(*) FROM users us WHERE us.service_id = s.id AND us.deleted_at IS NULL) AS nb_utilisateurs
                FROM services s
                LEFT JOIN users u ON u.id = s.responsable_id
                WHERE s.id = ?";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$id]);
        return $stmt->fetch() ?: null;
    }

    public function findByType(string $type): array {
        $stmt = $this->db->prepare(
            "SELECT * FROM services WHERE type = ? AND is_active = 1 ORDER BY nom"
        );
        $stmt->execute([$type]);
        return $stmt->fetchAll();
    }

    public function getBudgetConsommation(int $serviceId, int $exerciceId): array {
        $sql = "SELECT b.montant_prevu,
                       pc.numero_compte, pc.libelle AS compte_libelle,
                       COALESCE(SUM(l.debit), 0) AS consomme,
                       b.montant_prevu - COALESCE(SUM(l.debit), 0) AS restant
                FROM budgets b
                JOIN plan_comptable pc ON pc.id = b.compte_id
                LEFT JOIN lignes_ecriture l ON l.compte_id = b.compte_id
                LEFT JOIN ecritures_comptables e ON e.id = l.ecriture_id
                    AND e.exercice_id = b.exercice_id
                    AND e.statut = 'VALIDE'
                WHERE b.service_id = ?
                  AND b.exercice_id = ?
                  AND b.statut = 'APPROUVE'
                GROUP BY b.id, pc.numero_compte, pc.libelle, b.montant_prevu";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$serviceId, $exerciceId]);
        return $stmt->fetchAll();
    }
}