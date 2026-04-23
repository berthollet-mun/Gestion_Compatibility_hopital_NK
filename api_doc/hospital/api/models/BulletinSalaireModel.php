<?php
// api/models/BulletinSalaireModel.php

require_once __DIR__ . '/BaseModel.php';

class BulletinSalaireModel extends BaseModel {
    protected string $table = 'bulletins_salaire';

    public function getAllPaginated(int $page = 1, int $perPage = 20, array $filters = []): array {
        $offset = ($page - 1) * $perPage;
        $where  = ['1=1'];
        $params = [];

        if (!empty($filters['employe_id'])) {
            $where[]  = 'bs.employe_id = ?';
            $params[] = (int)$filters['employe_id'];
        }
        if (!empty($filters['mois'])) {
            $where[]  = 'bs.mois = ?';
            $params[] = (int)$filters['mois'];
        }
        if (!empty($filters['annee'])) {
            $where[]  = 'bs.annee = ?';
            $params[] = (int)$filters['annee'];
        }
        if (!empty($filters['statut'])) {
            $where[]  = 'bs.statut = ?';
            $params[] = $filters['statut'];
        }

        $whereClause = implode(' AND ', $where);

        $stmtC = $this->db->prepare("SELECT COUNT(*) FROM bulletins_salaire bs WHERE {$whereClause}");
        $stmtC->execute($params);
        $total = (int)$stmtC->fetchColumn();

        $sql = "SELECT bs.*,
                       CONCAT(em.nom, ' ', em.prenom) AS employe_nom,
                       em.matricule AS employe_matricule,
                       s.nom AS service_nom,
                       c.poste
                FROM bulletins_salaire bs
                JOIN employes em ON em.id = bs.employe_id
                JOIN services s ON s.id = em.service_id
                JOIN contrats c ON c.id = bs.contrat_id
                WHERE {$whereClause}
                ORDER BY bs.annee DESC, bs.mois DESC
                LIMIT ? OFFSET ?";

        $params[] = $perPage;
        $params[] = $offset;

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);

        return ['data' => $stmt->fetchAll(), 'total' => $total];
    }

    public function findWithDetails(int $id): ?array {
        $sql = "SELECT bs.*,
                       CONCAT(em.nom, ' ', em.prenom) AS employe_nom,
                       em.matricule, em.numero_cnss,
                       s.nom AS service_nom,
                       c.poste, c.type_contrat, c.categorie,
                       CONCAT(u.nom, ' ', u.prenom) AS valide_par_nom
                FROM bulletins_salaire bs
                JOIN employes em ON em.id = bs.employe_id
                JOIN services s ON s.id = em.service_id
                JOIN contrats c ON c.id = bs.contrat_id
                LEFT JOIN users u ON u.id = bs.valide_par
                WHERE bs.id = ?";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$id]);
        return $stmt->fetch() ?: null;
    }

    public function existsForPeriod(int $employeId, int $mois, int $annee): bool {
        $stmt = $this->db->prepare(
            "SELECT COUNT(*) FROM bulletins_salaire WHERE employe_id = ? AND mois = ? AND annee = ?"
        );
        $stmt->execute([$employeId, $mois, $annee]);
        return (int)$stmt->fetchColumn() > 0;
    }

    public function getMasseSalarialeMensuelle(int $mois, int $annee): array {
        $sql = "SELECT
                    COUNT(*) AS nb_bulletins,
                    SUM(total_brut) AS masse_brute,
                    SUM(net_a_payer) AS masse_nette,
                    SUM(cotis_cnss) AS total_cnss,
                    SUM(ipr) AS total_ipr,
                    SUM(avances_deduites) AS total_avances
                FROM bulletins_salaire
                WHERE mois = ? AND annee = ? AND statut != 'BROUILLON'";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$mois, $annee]);
        return $stmt->fetch();
    }
}