<?php
// api/models/JournalModel.php

require_once __DIR__ . '/BaseModel.php';

class JournalModel extends BaseModel {
    protected string $table = 'journaux';

    public function findAllActive(): array {
        return $this->query(
            "SELECT * FROM journaux WHERE is_active = 1 ORDER BY code"
        );
    }

    public function findByCode(string $code): ?array {
        $stmt = $this->db->prepare(
            "SELECT * FROM journaux WHERE code = ? LIMIT 1"
        );
        $stmt->execute([$code]);
        return $stmt->fetch() ?: null;
    }

    public function findByType(string $type): array {
        $stmt = $this->db->prepare(
            "SELECT * FROM journaux WHERE type = ? AND is_active = 1"
        );
        $stmt->execute([$type]);
        return $stmt->fetchAll();
    }

    public function getEcrituresParJournal(int $journalId, int $exerciceId, int $page = 1, int $perPage = 20): array {
        $offset = ($page - 1) * $perPage;

        $stmtC = $this->db->prepare(
            "SELECT COUNT(*) FROM ecritures_comptables WHERE journal_id = ? AND exercice_id = ?"
        );
        $stmtC->execute([$journalId, $exerciceId]);
        $total = (int)$stmtC->fetchColumn();

        $sql = "SELECT e.*,
                       CONCAT(u.nom, ' ', u.prenom) AS saisi_par_nom,
                       (SELECT SUM(l.debit) FROM lignes_ecriture l WHERE l.ecriture_id = e.id) AS total_debit,
                       (SELECT SUM(l.credit) FROM lignes_ecriture l WHERE l.ecriture_id = e.id) AS total_credit
                FROM ecritures_comptables e
                JOIN users u ON u.id = e.saisi_par
                WHERE e.journal_id = ? AND e.exercice_id = ?
                ORDER BY e.date_ecriture DESC
                LIMIT ? OFFSET ?";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([$journalId, $exerciceId, $perPage, $offset]);

        return ['data' => $stmt->fetchAll(), 'total' => $total];
    }

    public function getStatistiques(int $journalId, int $exerciceId): array {
        $sql = "SELECT COUNT(*) AS nb_ecritures,
                       COUNT(CASE WHEN statut = 'VALIDE' THEN 1 END) AS nb_validees,
                       COUNT(CASE WHEN statut = 'BROUILLON' THEN 1 END) AS nb_brouillons,
                       COUNT(CASE WHEN statut = 'SOUMIS' THEN 1 END) AS nb_soumises
                FROM ecritures_comptables
                WHERE journal_id = ? AND exercice_id = ?";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$journalId, $exerciceId]);
        return $stmt->fetch();
    }
}