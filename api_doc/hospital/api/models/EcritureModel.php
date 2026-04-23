<?php
// api/models/EcritureModel.php

require_once __DIR__ . '/BaseModel.php';

class EcritureModel extends BaseModel {
    protected string $table = 'ecritures_comptables';

    public function getAllPaginated(int $page = 1, int $perPage = 20, array $filters = []): array {
        $offset = ($page - 1) * $perPage;
        $where  = ['1=1'];
        $params = [];

        if (!empty($filters['exercice_id'])) {
            $where[]  = 'e.exercice_id = ?';
            $params[] = $filters['exercice_id'];
        }
        if (!empty($filters['journal_id'])) {
            $where[]  = 'e.journal_id = ?';
            $params[] = $filters['journal_id'];
        }
        if (!empty($filters['statut'])) {
            $where[]  = 'e.statut = ?';
            $params[] = $filters['statut'];
        }
        if (!empty($filters['date_debut'])) {
            $where[]  = 'e.date_ecriture >= ?';
            $params[] = $filters['date_debut'];
        }
        if (!empty($filters['date_fin'])) {
            $where[]  = 'e.date_ecriture <= ?';
            $params[] = $filters['date_fin'];
        }

        $whereClause = implode(' AND ', $where);

        $sqlCount = "SELECT COUNT(*) FROM ecritures_comptables e WHERE {$whereClause}";
        $stmtC    = $this->db->prepare($sqlCount);
        $stmtC->execute($params);
        $total = (int) $stmtC->fetchColumn();

        $sql = "SELECT e.*,
                       j.libelle AS journal_libelle, j.code AS journal_code,
                       CONCAT(u.nom, ' ', u.prenom) AS saisi_par_nom,
                       CONCAT(v.nom, ' ', v.prenom) AS valide_par_nom
                FROM ecritures_comptables e
                JOIN journaux j ON j.id = e.journal_id
                JOIN users u ON u.id = e.saisi_par
                LEFT JOIN users v ON v.id = e.valide_par
                WHERE {$whereClause}
                ORDER BY e.date_ecriture DESC, e.id DESC
                LIMIT ? OFFSET ?";

        $params[] = $perPage;
        $params[] = $offset;

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);

        return ['data' => $stmt->fetchAll(), 'total' => $total];
    }

    public function findWithLignes(int $id): ?array {
        $ecriture = $this->findById($id);
        if (!$ecriture) return null;

        $sql  = "SELECT l.*, pc.numero_compte, pc.libelle AS compte_libelle
                 FROM lignes_ecriture l
                 JOIN plan_comptable pc ON pc.id = l.compte_id
                 WHERE l.ecriture_id = ?
                 ORDER BY l.ordre";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$id]);
        $ecriture['lignes'] = $stmt->fetchAll();

        return $ecriture;
    }

    public function isEquilibree(array $lignes): bool {
        $totalDebit  = array_sum(array_column($lignes, 'debit'));
        $totalCredit = array_sum(array_column($lignes, 'credit'));
        return abs($totalDebit - $totalCredit) < 0.01; // tolérance arrondi
    }

    public function creerAvecLignes(array $ecriture, array $lignes, int $userId): int {
        $this->db->beginTransaction();
        try {
            // Générer numéro de pièce
            $ecriture['numero_piece'] = $this->genererNumeroPiece(
                $ecriture['exercice_id'],
                $ecriture['journal_id']
            );
            $ecriture['saisi_par'] = $userId;

            $ecritureId = $this->create($ecriture);

            // Insérer les lignes
            $sqlLigne = "INSERT INTO lignes_ecriture
                            (ecriture_id, compte_id, libelle, debit, credit, devise, taux_change, ordre)
                         VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
            $stmtL = $this->db->prepare($sqlLigne);

            foreach ($lignes as $index => $ligne) {
                $stmtL->execute([
                    $ecritureId,
                    $ligne['compte_id'],
                    $ligne['libelle'] ?? '',
                    (float)($ligne['debit'] ?? 0),
                    (float)($ligne['credit'] ?? 0),
                    $ligne['devise'] ?? 'CDF',
                    (float)($ligne['taux_change'] ?? 1),
                    $index + 1
                ]);
            }

            $this->db->commit();
            return $ecritureId;

        } catch (Exception $e) {
            $this->db->rollBack();
            throw $e;
        }
    }

    private function genererNumeroPiece(int $exerciceId, int $journalId): string {
        $sql  = "SELECT code FROM journaux WHERE id = ?";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$journalId]);
        $journal = $stmt->fetch();

        $sqlCount = "SELECT COUNT(*) FROM ecritures_comptables
                     WHERE exercice_id = ? AND journal_id = ?";
        $stmtC = $this->db->prepare($sqlCount);
        $stmtC->execute([$exerciceId, $journalId]);
        $count = (int)$stmtC->fetchColumn() + 1;

        return sprintf('%s-%s-%05d', $journal['code'], date('Y'), $count);
    }
}