<?php
// api/controllers/ServiceController.php

require_once __DIR__ . '/../models/ServiceModel.php';
require_once __DIR__ . '/../helpers/ResponseHelper.php';
require_once __DIR__ . '/../helpers/AuditHelper.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../middleware/RoleMiddleware.php';
require_once __DIR__ . '/../middleware/ValidationMiddleware.php';

class ServiceController {
    private ServiceModel $serviceModel;

    public function __construct() {
        $this->serviceModel = new ServiceModel();
    }

    /** GET /api/services */
    public function index(): void {
        $user     = AuthMiddleware::handle();
        $services = $this->serviceModel->findAllActive();
        ResponseHelper::success($services, 'Liste des services');
    }

    /** GET /api/services/{id} */
    public function show(int $id): void {
        $user    = AuthMiddleware::handle();
        $service = $this->serviceModel->findWithStats($id);
        if (!$service) ResponseHelper::error('Service introuvable', 404);

        ResponseHelper::success($service, 'Service trouvé');
    }

    /** POST /api/services */
    public function store(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN', 'DIRECTEUR']);

        $data = ValidationMiddleware::getJsonBody();

        ValidationMiddleware::make($data)
            ->required('nom', 'Nom du service')
            ->required('code', 'Code')
            ->required('type', 'Type')
            ->maxLength('code', 10)
            ->inArray('type', ['MEDICAL', 'ADMINISTRATIF', 'TECHNIQUE', 'PARAMEDICAL'])
            ->unique('code', 'services', 'code')
            ->validated();

        $id = $this->serviceModel->create([
            'nom'            => $data['nom'],
            'code'           => strtoupper($data['code']),
            'type'           => $data['type'],
            'responsable_id' => !empty($data['responsable_id']) ? (int)$data['responsable_id'] : null,
            'budget_annuel'  => !empty($data['budget_annuel']) ? (float)$data['budget_annuel'] : null,
            'is_active'      => 1,
        ]);

        $created = $this->serviceModel->findWithStats($id);
        AuditHelper::log($user['id'], 'CREATE_SERVICE', 'services', $id, null, $created);
        ResponseHelper::success($created, 'Service créé', 201);
    }

    /** PUT /api/services/{id} */
    public function update(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN', 'DIRECTEUR']);

        $existing = $this->serviceModel->findById($id);
        if (!$existing) ResponseHelper::error('Service introuvable', 404);

        $data    = ValidationMiddleware::getJsonBody();
        $allowed = ['nom', 'type', 'responsable_id', 'budget_annuel', 'is_active'];

        $updateData = [];
        foreach ($allowed as $field) {
            if (isset($data[$field])) $updateData[$field] = $data[$field];
        }

        $this->serviceModel->update($id, $updateData);
        $updated = $this->serviceModel->findWithStats($id);

        AuditHelper::log($user['id'], 'UPDATE_SERVICE', 'services', $id, $existing, $updateData);
        ResponseHelper::success($updated, 'Service mis à jour');
    }

    /** DELETE /api/services/{id} */
    public function destroy(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN']);

        $existing = $this->serviceModel->findById($id);
        if (!$existing) ResponseHelper::error('Service introuvable', 404);

        $this->serviceModel->update($id, ['is_active' => 0]);
        AuditHelper::log($user['id'], 'DELETE_SERVICE', 'services', $id, $existing);
        ResponseHelper::success(null, 'Service désactivé');
    }

    /** GET /api/services/{id}/budget */
    public function budget(int $id): void {
        $user       = AuthMiddleware::handle();
        $exerciceId = (int)($_GET['exercice_id'] ?? 0);

        if (!$exerciceId) ResponseHelper::error('exercice_id requis', 400);

        $data = $this->serviceModel->getBudgetConsommation($id, $exerciceId);
        ResponseHelper::success($data, 'Budget du service');
    }
}