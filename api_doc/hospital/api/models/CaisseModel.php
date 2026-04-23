<?php
// api/models/CaisseModel.php

require_once __DIR__ . '/BaseModel.php';

class CaisseModel extends BaseModel {
    protected string $table = 'caisses';

    public function findAllWithStats(): array {
        $sql = "SELECT c.*,
                       s.nom AS service_nom,
                       CONCAT(u.nom, ' ', u.prenom) AS responsable_nom,
                       (SELECT COUNT(*) FROM sessions_caisse sc WHERE sc.caisse_id = c.id AND sc.date_session = CURDATE() AND sc.statut = 'OUVERTE') AS session_ouverte_today
                FROM caisses c
                LEFT JOIN services s ON s.id = c.service_id
                JOIN users u ON u.id = c.responsable_id
                WHERE c.is_active = 1
                ORDER BY c.nom";
        return $this->query($sql);
    }

    public function findWithTransactions(int $id, string $date): array {
        $caisse = $this->findById($id);
        if (!$caisse) return [];

        $sql = "SELECT tc.*
                FROM transactions_caisse tc
                JOIN sessions_caisse sc ON sc.id = tc.session_id
                WHERE sc.caisse_id = ? AND sc.date_session = ?
                ORDER BY tc.created_at DESC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$id, $date]);
        $caisse['transactions'] = $stmt->fetchAll();

        return $caisse;
    }

    public function getSessionActive(int $caisseId): ?array {
        $stmt = $this->db->prepare(
            "SELECT * FROM sessions_caisse
             WHERE caisse_id = ? AND date_session = CURDATE() AND statut = 'OUVERTE'
             LIMIT 1"
        );
        $stmt->execute([$caisseId]);
        return $stmt->fetch() ?: null;
    }

    public function updateSolde(int $id, float $delta): bool {
        return $this->execute(
            "UPDATE caisses SET solde_actuel = solde_actuel + ? WHERE id = ?",
            [$delta, $id]
        );
    }
}