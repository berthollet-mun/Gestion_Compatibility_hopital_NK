<?php
// api/models/EmployeModel.php

require_once __DIR__ . '/BaseModel.php';

class EmployeModel extends BaseModel {
    protected string $table = 'employes';

    public function getAllPaginated(int $page = 1, int $perPage = 20, array $filters = []): array {
        $offset = ($page - 1) * $perPage;
        $where  = ['1=1'];
        $params = [];

        if (!empty($filters['service_id'])) {
            $where[]  = 'em.service_id = ?';
            $params[] = (int)$filters['service_id'];
        }
        if (!empty($filters['statut'])) {
            $where[]  = 'em.statut = ?';
            $params[] = $filters['statut'];
        }
        if (!empty($filters['search'])) {
            $where[]  = '(em.nom LIKE ? OR em.prenom LIKE ? OR em.matricule LIKE ?)';
            $s        = '%' . $filters['search'] . '%';
            $params   = [...$params, $s, $s, $s];
        }

        $whereClause = implode(' AND ', $where);

        $stmtC = $this->db->prepare("SELECT COUNT(*) FROM employes em WHERE {$whereClause}");
        $stmtC->execute($params);
        $total = (int)$stmtC->fetchColumn();

        $sql = "SELECT em.*, s.nom AS service_nom,
                       c.poste, c.type_contrat, c.salaire_base, c.is_actif AS contrat_actif
                FROM employes em
                JOIN services s ON s.id = em.service_id
                LEFT JOIN contrats c ON c.employe_id = em.id AND c.is_actif = 1
                WHERE {$whereClause}
                ORDER BY em.nom ASC
                LIMIT ? OFFSET ?";

        $params[] = $perPage;
        $params[] = $offset;

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);

        return ['data' => $stmt->fetchAll(), 'total' => $total];
    }

    public function findWithContrats(int $id): ?array {
        $employe = $this->findById($id);
        if (!$employe) return null;

        $stmt = $this->db->prepare(
            "SELECT c.*, CONCAT(u.nom, ' ', u.prenom) AS signe_par_nom
             FROM contrats c
             LEFT JOIN users u ON u.id = c.signe_par
             WHERE c.employe_id = ?
             ORDER BY c.date_debut DESC"
        );
        $stmt->execute([$id]);
        $employe['contrats'] = $stmt->fetchAll();

        return $employe;
    }

    public function getContratActif(int $employeId): ?array {
        $stmt = $this->db->prepare(
            "SELECT * FROM contrats WHERE employe_id = ? AND is_actif = 1 LIMIT 1"
        );
        $stmt->execute([$employeId]);
        return $stmt->fetch() ?: null;
    }

    public function findByMatricule(string $matricule): ?array {
        $stmt = $this->db->prepare(
            "SELECT * FROM employes WHERE matricule = ? LIMIT 1"
        );
        $stmt->execute([$matricule]);
        return $stmt->fetch() ?: null;
    }

    public function getMassesSalariales(int $exerciceId): array {
        $sql = "SELECT s.nom AS service_nom,
                       COUNT(bs.id) AS nb_bulletins,
                       SUM(bs.net_a_payer) AS total_net,
                       SUM(bs.total_brut) AS total_brut,
                       SUM(bs.cotis_cnss) AS total_cnss,
                       SUM(bs.ipr) AS total_ipr
                FROM bulletins_salaire bs
                JOIN employes em ON em.id = bs.employe_id
                JOIN services s ON s.id = em.service_id
                WHERE bs.exercice_id = ?
                  AND bs.statut = 'PAYE'
                GROUP BY s.id, s.nom
                ORDER BY total_net DESC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$exerciceId]);
        return $stmt->fetchAll();
    }
}