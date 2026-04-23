<?php
// api/controllers/UserController.php

require_once __DIR__ . '/../models/UserModel.php';
require_once __DIR__ . '/../helpers/ResponseHelper.php';
require_once __DIR__ . '/../helpers/PasswordHelper.php';
require_once __DIR__ . '/../helpers/AuditHelper.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../middleware/RoleMiddleware.php';
require_once __DIR__ . '/../middleware/ValidationMiddleware.php';

class UserController {
    private UserModel $userModel;

    public function __construct() {
        $this->userModel = new UserModel();
    }

    /** GET /api/users */
    public function index(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'users.read');

        $page    = (int) ($_GET['page'] ?? 1);
        $perPage = (int) ($_GET['per_page'] ?? 20);
        $filters = [
            'role_id'    => $_GET['role_id'] ?? null,
            'service_id' => $_GET['service_id'] ?? null,
            'search'     => $_GET['search'] ?? null,
        ];

        $result = $this->userModel->getAllPaginated($page, $perPage, $filters);

        ResponseHelper::paginated(
            $result['data'],
            $result['total'],
            $page,
            $perPage,
            'Liste des utilisateurs'
        );
    }

    /** GET /api/users/{id} */
    public function show(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'users.read');

        $targetUser = $this->userModel->getWithPermissions($id);
        if (!$targetUser) {
            ResponseHelper::error('Utilisateur introuvable', 404);
        }

        ResponseHelper::success($targetUser, 'Utilisateur trouvé');
    }

    /** POST /api/users */
    public function store(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'users.create');

        $data = ValidationMiddleware::getJsonBody();

        ValidationMiddleware::make($data)
            ->required('nom', 'Nom')
            ->required('prenom', 'Prénom')
            ->required('email', 'Email')
            ->required('role_id', 'Rôle')
            ->required('matricule', 'Matricule')
            ->email('email')
            ->unique('email', 'users', 'email')
            ->unique('matricule', 'users', 'matricule')
            ->validated();

        $defaultPassword = 'Hopital@' . date('Y') . '!';

        $newUser = [
            'role_id'         => (int)$data['role_id'],
            'service_id'      => !empty($data['service_id']) ? (int)$data['service_id'] : null,
            'matricule'       => strtoupper($data['matricule']),
            'nom'             => strtoupper($data['nom']),
            'prenom'          => ucwords(strtolower($data['prenom'])),
            'email'           => strtolower($data['email']),
            'telephone'       => $data['telephone'] ?? null,
            'password_hash'   => PasswordHelper::hash($defaultPassword),
            'is_active'       => 1,
            'must_change_pwd' => 1,
            'created_by'      => $user['id'],
        ];

        $newId    = $this->userModel->create($newUser);
        $created  = $this->userModel->getWithPermissions($newId);

        AuditHelper::log($user['id'], 'CREATE_USER', 'users', $newId, null, $created);

        ResponseHelper::success(
            array_merge($created, ['temp_password' => $defaultPassword]),
            'Utilisateur créé avec succès',
            201
        );
    }

    /** PUT /api/users/{id} */
    public function update(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'users.update');

        $existing = $this->userModel->findById($id);
        if (!$existing) {
            ResponseHelper::error('Utilisateur introuvable', 404);
        }

        $data = ValidationMiddleware::getJsonBody();

        ValidationMiddleware::make($data)
            ->email('email')
            ->unique('email', 'users', 'email', $id)
            ->unique('matricule', 'users', 'matricule', $id)
            ->validated();

        $updateData = [];
        $allowed = ['nom', 'prenom', 'email', 'telephone', 'role_id', 'service_id', 'is_active'];

        foreach ($allowed as $field) {
            if (isset($data[$field])) {
                $updateData[$field] = $data[$field];
            }
        }

        if (empty($updateData)) {
            ResponseHelper::error('Aucune donnée à mettre à jour', 400);
        }

        $this->userModel->update($id, $updateData);
        $updated = $this->userModel->getWithPermissions($id);

        AuditHelper::log($user['id'], 'UPDATE_USER', 'users', $id, $existing, $updateData);
        ResponseHelper::success($updated, 'Utilisateur mis à jour');
    }

    /** DELETE /api/users/{id} */
    public function destroy(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'users.delete');

        if ($id === $user['id']) {
            ResponseHelper::error('Impossible de supprimer votre propre compte', 400);
        }

        $existing = $this->userModel->findById($id);
        if (!$existing) {
            ResponseHelper::error('Utilisateur introuvable', 404);
        }

        $this->userModel->delete($id);
        AuditHelper::log($user['id'], 'DELETE_USER', 'users', $id, $existing, null);
        ResponseHelper::success(null, 'Utilisateur supprimé');
    }

    /** POST /api/users/{id}/reset-password */
    public function resetPassword(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN', 'CHEF_COMPTABLE']);

        $existing = $this->userModel->findById($id);
        if (!$existing) {
            ResponseHelper::error('Utilisateur introuvable', 404);
        }

        $newPassword = 'Reset@' . rand(1000, 9999) . '!';
        $this->userModel->update($id, [
            'password_hash'   => PasswordHelper::hash($newPassword),
            'must_change_pwd' => 1,
            'failed_attempts' => 0,
            'locked_until'    => null,
        ]);

        AuditHelper::log($user['id'], 'RESET_PASSWORD', 'users', $id);
        ResponseHelper::success(['new_password' => $newPassword], 'Mot de passe réinitialisé');
    }
}