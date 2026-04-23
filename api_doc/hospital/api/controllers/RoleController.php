<?php
// api/controllers/RoleController.php

require_once __DIR__ . '/../models/RoleModel.php';
require_once __DIR__ . '/../helpers/ResponseHelper.php';
require_once __DIR__ . '/../helpers/AuditHelper.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../middleware/RoleMiddleware.php';
require_once __DIR__ . '/../middleware/ValidationMiddleware.php';

class RoleController {
    private RoleModel $roleModel;

    public function __construct() {
        $this->roleModel = new RoleModel();
    }

    /** GET /api/roles */
    public function index(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'users.read');

        $roles = $this->roleModel->findAllActive();
        ResponseHelper::success($roles, 'Liste des rôles');
    }

    /** GET /api/roles/{id} */
    public function show(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'users.read');

        $role = $this->roleModel->findWithPermissions($id);
        if (!$role) ResponseHelper::error('Rôle introuvable', 404);

        ResponseHelper::success($role, 'Rôle trouvé');
    }

    /** POST /api/roles */
    public function store(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN']);

        $data = ValidationMiddleware::getJsonBody();

        ValidationMiddleware::make($data)
            ->required('nom', 'Nom du rôle')
            ->required('niveau', 'Niveau')
            ->minLength('nom', 3)
            ->maxLength('nom', 50)
            ->numeric('niveau')
            ->unique('nom', 'roles', 'nom')
            ->validated();

        $id = $this->roleModel->create([
            'nom'         => strtoupper($data['nom']),
            'description' => $data['description'] ?? null,
            'niveau'      => (int)$data['niveau'],
            'is_active'   => 1,
        ]);

        // Attribuer les permissions si fournies
        if (!empty($data['permission_ids']) && is_array($data['permission_ids'])) {
            $this->roleModel->syncPermissions($id, $data['permission_ids']);
        }

        $created = $this->roleModel->findWithPermissions($id);
        AuditHelper::log($user['id'], 'CREATE_ROLE', 'roles', $id, null, $created);
        ResponseHelper::success($created, 'Rôle créé avec succès', 201);
    }

    /** PUT /api/roles/{id} */
    public function update(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN']);

        $existing = $this->roleModel->findById($id);
        if (!$existing) ResponseHelper::error('Rôle introuvable', 404);

        $data = ValidationMiddleware::getJsonBody();

        $updateData = [];
        if (isset($data['description'])) $updateData['description'] = $data['description'];
        if (isset($data['niveau']))      $updateData['niveau']      = (int)$data['niveau'];
        if (isset($data['is_active']))   $updateData['is_active']   = (int)$data['is_active'];

        if (!empty($updateData)) {
            $this->roleModel->update($id, $updateData);
        }

        // Synchroniser les permissions
        if (isset($data['permission_ids']) && is_array($data['permission_ids'])) {
            $this->roleModel->syncPermissions($id, $data['permission_ids']);
        }

        $updated = $this->roleModel->findWithPermissions($id);
        AuditHelper::log($user['id'], 'UPDATE_ROLE', 'roles', $id, $existing, $updateData);
        ResponseHelper::success($updated, 'Rôle mis à jour');
    }

    /** GET /api/roles/permissions */
    public function allPermissions(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN']);

        $permissions = $this->roleModel->getAllPermissions();

        // Grouper par module
        $grouped = [];
        foreach ($permissions as $perm) {
            $grouped[$perm['module']][] = $perm;
        }

        ResponseHelper::success($grouped, 'Toutes les permissions');
    }

    /** DELETE /api/roles/{id} */
    public function destroy(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN']);

        $existing = $this->roleModel->findById($id);
        if (!$existing) ResponseHelper::error('Rôle introuvable', 404);

        $nbUsers = $this->roleModel->countUsersByRole($id);
        if ($nbUsers > 0) {
            ResponseHelper::error("Impossible de supprimer : {$nbUsers} utilisateur(s) ont ce rôle", 400);
        }

        $this->roleModel->update($id, ['is_active' => 0]);
        AuditHelper::log($user['id'], 'DELETE_ROLE', 'roles', $id, $existing);
        ResponseHelper::success(null, 'Rôle désactivé');
    }
}