<?php
// api/models/ExerciceModel.php

require_once __DIR__ . '/BaseModel.php';

class ExerciceModel extends BaseModel {
    protected string $table = 'exercices_fiscaux';

    public function findCurrent(): ?array {
        $stmt = $this->db->prepare(
            "SELECT * FROM exercices_fiscaux WHERE statut = 'OUVERT' ORDER BY annee DESC LIMIT 1"
        );
        $stmt->execute();
        return $stmt->fetch() ?: null;
    }

    public function findByAnnee(int $annee): ?array {
        $stmt = $this->db->prepare(
            "SELECT * FROM exercices_fiscaux WHERE annee = ? LIMIT 1"
        );
        $stmt->execute([$annee]);
        return $stmt->fetch() ?: null;
    }

    public function findAllWithStats(): array {
        $sql = "SELECT ef.*,
                       CONCAT(u.nom, ' ', u.prenom) AS cloture_par_nom,
                       (SELECT COUNT(*) FROM ecritures_comptables e WHERE e.exercice_id = ef.id) AS nb_ecritures,
                       (SELECT COUNT(*) FROM ecritures_comptables e WHERE e.exercice_id = ef.id AND e.statut = 'VALIDE') AS nb_ecritures_validees,
                       (SELECT COUNT(*) FROM budgets b WHERE b.exercice_id = ef.id) AS nb_budgets
                FROM exercices_fiscaux ef
                LEFT JOIN users u ON u.id = ef.cloture_par
                ORDER BY ef.annee DESC";
        return $this->query($sql);
    }

    public function cloturerTemporairement(int $id, int $userId): bool {
        return $this->update($id, [
            'statut'     => 'CLOTURE_TEMP',
            'cloture_par'=> $userId,
            'cloture_le' => date('Y-m-d H:i:s'),
        ]);
    }

    public function cloturerDefinitivement(int $id, int $userId): bool {
        return $this->update($id, [
            'statut'     => 'CLOTURE_DEF',
            'cloture_par'=> $userId,
            'cloture_le' => date('Y-m-d H:i:s'),
        ]);
    }

    public function rouvrir(int $id): bool {
        return $this->update($id, [
            'statut'     => 'OUVERT',
            'cloture_par'=> null,
            'cloture_le' => null,
        ]);
    }

    public function isOuvert(int $id): bool {
        $stmt = $this->db->prepare(
            "SELECT statut FROM exercices_fiscaux WHERE id = ?"
        );
        $stmt->execute([$id]);
        $row = $stmt->fetch();
        return $row && $row['statut'] === 'OUVERT';
    }
}