<?php
// api/models/PlanComptableModel.php

require_once __DIR__ . '/BaseModel.php';

class PlanComptableModel extends BaseModel {
    protected string $table = 'plan_comptable';

    public function findByNumero(string $numero): ?array {
        $stmt = $this->db->prepare(
            "SELECT * FROM plan_comptable WHERE numero_compte = ? LIMIT 1"
        );
        $stmt->execute([$numero]);
        return $stmt->fetch() ?: null;
    }

    public function findByClasse(int $classe): array {
        $stmt = $this->db->prepare(
            "SELECT * FROM plan_comptable WHERE classe = ? AND is_active = 1 ORDER BY numero_compte"
        );
        $stmt->execute([$classe]);
        return $stmt->fetchAll();
    }

    public function findByType(string $type): array {
        $stmt = $this->db->prepare(
            "SELECT * FROM plan_comptable WHERE type_compte = ? AND is_active = 1 ORDER BY numero_compte"
        );
        $stmt->execute([$type]);
        return $stmt->fetchAll();
    }

    public function searchComptes(string $term): array {
        $like = '%' . $term . '%';
        $stmt = $this->db->prepare(
            "SELECT * FROM plan_comptable
             WHERE (numero_compte LIKE ? OR libelle LIKE ?)
               AND is_active = 1
             ORDER BY numero_compte
             LIMIT 50"
        );
        $stmt->execute([$like, $like]);
        return $stmt->fetchAll();
    }

    public function getAllPaginated(int $page = 1, int $perPage = 50, array $filters = []): array {
        $offset = ($page - 1) * $perPage;
        $where  = ['is_active = 1'];
        $params = [];

        if (!empty($filters['classe'])) {
            $where[]  = 'classe = ?';
            $params[] = (int)$filters['classe'];
        }
        if (!empty($filters['type_compte'])) {
            $where[]  = 'type_compte = ?';
            $params[] = $filters['type_compte'];
        }
        if (!empty($filters['search'])) {
            $where[]  = '(numero_compte LIKE ? OR libelle LIKE ?)';
            $s        = '%' . $filters['search'] . '%';
            $params[] = $s;
            $params[] = $s;
        }

        $whereClause = implode(' AND ', $where);

        $stmtC = $this->db->prepare("SELECT COUNT(*) FROM plan_comptable WHERE {$whereClause}");
        $stmtC->execute($params);
        $total = (int)$stmtC->fetchColumn();

        $sql  = "SELECT * FROM plan_comptable WHERE {$whereClause} ORDER BY numero_compte LIMIT ? OFFSET ?";
        $params[] = $perPage;
        $params[] = $offset;

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);

        return ['data' => $stmt->fetchAll(), 'total' => $total];
    }

    public function getSolde(int $compteId, ?int $exerciceId = null, ?string $dateDebut = null, ?string $dateFin = null): array {
        $where  = ['l.compte_id = ?', 'e.statut = \'VALIDE\''];
        $params = [$compteId];

        if ($exerciceId) {
            $where[]  = 'e.exercice_id = ?';
            $params[] = $exerciceId;
        }
        if ($dateDebut) {
            $where[]  = 'e.date_ecriture >= ?';
            $params[] = $dateDebut;
        }
        if ($dateFin) {
            $where[]  = 'e.date_ecriture <= ?';
            $params[] = $dateFin;
        }

        $whereClause = implode(' AND ', $where);

        $sql  = "SELECT COALESCE(SUM(l.debit), 0) AS total_debit,
                        COALESCE(SUM(l.credit), 0) AS total_credit
                 FROM lignes_ecriture l
                 JOIN ecritures_comptables e ON e.id = l.ecriture_id
                 WHERE {$whereClause}";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $totaux = $stmt->fetch();

        return [
            'total_debit'  => (float)$totaux['total_debit'],
            'total_credit' => (float)$totaux['total_credit'],
            'solde'        => (float)$totaux['total_debit'] - (float)$totaux['total_credit'],
        ];
    }

    public function getArborescence(): array {
        $all     = $this->query("SELECT * FROM plan_comptable WHERE is_active = 1 ORDER BY numero_compte");
        $tree    = [];
        $indexed = [];

        foreach ($all as $item) {
            $indexed[$item['numero_compte']] = array_merge($item, ['children' => []]);
        }

        foreach ($indexed as $num => $item) {
            if ($item['compte_parent'] && isset($indexed[$item['compte_parent']])) {
                $indexed[$item['compte_parent']]['children'][] = &$indexed[$num];
            } else {
                $tree[] = &$indexed[$num];
            }
        }

        return $tree;
    }
}