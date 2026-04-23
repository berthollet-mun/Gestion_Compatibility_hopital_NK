<?php
// api/models/UserModel.php

require_once __DIR__ . '/BaseModel.php';

class UserModel extends BaseModel {
    protected string $table = 'users';

    public function findByEmail(string $email): ?array {
        $sql  = "SELECT u.*, r.nom AS role_nom, r.niveau AS role_niveau
                 FROM users u
                 JOIN roles r ON r.id = u.role_id
                 WHERE u.email = ?
                   AND u.deleted_at IS NULL
                 LIMIT 1";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$email]);
        return $stmt->fetch() ?: null;
    }

    public function findByMatricule(string $matricule): ?array {
        $sql  = "SELECT * FROM users WHERE matricule = ? AND deleted_at IS NULL LIMIT 1";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$matricule]);
        return $stmt->fetch() ?: null;
    }

    public function findWithRole(int $id): ?array {
        $sql = "SELECT u.*, r.nom AS role_nom, r.niveau AS role_niveau,
                       s.nom AS service_nom
                FROM users u
                JOIN roles r ON r.id = u.role_id
                LEFT JOIN services s ON s.id = u.service_id
                WHERE u.id = ?
                  AND u.deleted_at IS NULL
                LIMIT 1";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$id]);
        return $stmt->fetch() ?: null;
    }

    public function getWithPermissions(int $id): ?array {
        $user = $this->findWithRole($id);
        if (!$user) return null;

        $sql  = "SELECT CONCAT(p.module, '.', p.action) AS permission
                 FROM role_permissions rp
                 JOIN permissions p ON p.id = rp.permission_id
                 WHERE rp.role_id = ?";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$user['role_id']]);
        $user['permissions'] = array_column($stmt->fetchAll(), 'permission');

        // Construire un objet role imbriqué attendu par Flutter
        $slugMap = [
            'SUPER_ADMIN'       => 'admin',
            'DIRECTEUR'         => 'directeur',
            'CHEF_COMPTABLE'    => 'chef-comptable',
            'AUDITEUR'          => 'auditeur-interne',
            'COMPTABLE'         => 'comptable',
            'CAISSIER'          => 'caissier',
            'GESTIONNAIRE_STOCK'=> 'gestionnaire-stock',
        ];
        $roleNom = $user['role_nom'] ?? '';
        $user['role'] = [
            'id'   => $user['role_id'],
            'nom'  => $roleNom,
            'slug' => $slugMap[$roleNom] ?? strtolower(str_replace('_', '-', $roleNom)),
        ];

        // Nettoyer les données sensibles
        unset($user['password_hash']);
        return $user;
    }

    public function getAllPaginated(int $page = 1, int $perPage = 20, array $filters = []): array {
        $offset = ($page - 1) * $perPage;
        $where  = ['u.deleted_at IS NULL'];
        $params = [];

        if (!empty($filters['role_id'])) {
            $where[]  = 'u.role_id = ?';
            $params[] = $filters['role_id'];
        }
        if (!empty($filters['service_id'])) {
            $where[]  = 'u.service_id = ?';
            $params[] = $filters['service_id'];
        }
        if (!empty($filters['search'])) {
            $where[]  = "(u.nom LIKE ? OR u.prenom LIKE ? OR u.matricule LIKE ?)";
            $search   = '%' . $filters['search'] . '%';
            $params   = [...$params, $search, $search, $search];
        }

        $whereClause = implode(' AND ', $where);

        $sqlCount = "SELECT COUNT(*) FROM users u WHERE {$whereClause}";
        $stmtC    = $this->db->prepare($sqlCount);
        $stmtC->execute($params);
        $total = (int) $stmtC->fetchColumn();

        $sql = "SELECT u.id, u.matricule, u.nom, u.prenom, u.email,
                       u.telephone, u.is_active, u.last_login, u.created_at,
                       r.nom AS role_nom, s.nom AS service_nom
                FROM users u
                JOIN roles r ON r.id = u.role_id
                LEFT JOIN services s ON s.id = u.service_id
                WHERE {$whereClause}
                ORDER BY u.nom ASC
                LIMIT ? OFFSET ?";

        $params[] = $perPage;
        $params[] = $offset;

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);

        return ['data' => $stmt->fetchAll(), 'total' => $total];
    }

    public function incrementFailedAttempts(int $id): void {
        $this->db->prepare(
            "UPDATE users SET failed_attempts = failed_attempts + 1 WHERE id = ?"
        )->execute([$id]);
    }

    public function lockAccount(int $id, int $minutes = 15): void {
        $this->db->prepare(
            "UPDATE users SET locked_until = DATE_ADD(NOW(), INTERVAL ? MINUTE) WHERE id = ?"
        )->execute([$minutes, $id]);
    }

    public function resetFailedAttempts(int $id): void {
        $this->db->prepare(
            "UPDATE users SET failed_attempts = 0, locked_until = NULL WHERE id = ?"
        )->execute([$id]);
    }

    public function updateLastLogin(int $id): void {
        $this->db->prepare(
            "UPDATE users SET last_login = NOW() WHERE id = ?"
        )->execute([$id]);
    }
}