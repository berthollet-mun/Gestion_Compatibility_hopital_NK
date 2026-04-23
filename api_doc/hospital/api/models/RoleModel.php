<?php
// api/models/RoleModel.php

require_once __DIR__ . '/BaseModel.php';

class RoleModel extends BaseModel {
    protected string $table = 'roles';

    public function findAllActive(): array {
        return $this->query(
            "SELECT * FROM roles WHERE is_active = 1 ORDER BY niveau DESC"
        );
    }

    public function findWithPermissions(int $id): ?array {
        $role = $this->findById($id);
        if (!$role) return null;

        $sql  = "SELECT p.id, p.module, p.action, p.description
                 FROM role_permissions rp
                 JOIN permissions p ON p.id = rp.permission_id
                 WHERE rp.role_id = ?
                 ORDER BY p.module, p.action";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$id]);
        $role['permissions'] = $stmt->fetchAll();

        return $role;
    }

    public function getAllPermissions(): array {
        return $this->query(
            "SELECT * FROM permissions ORDER BY module, action"
        );
    }

    public function syncPermissions(int $roleId, array $permissionIds): void {
        $this->db->beginTransaction();
        try {
            // Supprimer toutes les permissions actuelles
            $this->db->prepare(
                "DELETE FROM role_permissions WHERE role_id = ?"
            )->execute([$roleId]);

            // Réinsérer les nouvelles
            if (!empty($permissionIds)) {
                $sql  = "INSERT INTO role_permissions (role_id, permission_id) VALUES (?, ?)";
                $stmt = $this->db->prepare($sql);
                foreach ($permissionIds as $permId) {
                    $stmt->execute([$roleId, (int)$permId]);
                }
            }
            $this->db->commit();
        } catch (Exception $e) {
            $this->db->rollBack();
            throw $e;
        }
    }

    public function countUsersByRole(int $roleId): int {
        $stmt = $this->db->prepare(
            "SELECT COUNT(*) FROM users WHERE role_id = ? AND deleted_at IS NULL"
        );
        $stmt->execute([$roleId]);
        return (int) $stmt->fetchColumn();
    }
}