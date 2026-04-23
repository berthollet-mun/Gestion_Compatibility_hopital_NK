<?php
// api/controllers/PlanComptableController.php

require_once __DIR__ . '/../models/PlanComptableModel.php';
require_once __DIR__ . '/../helpers/ResponseHelper.php';
require_once __DIR__ . '/../helpers/AuditHelper.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../middleware/RoleMiddleware.php';
require_once __DIR__ . '/../middleware/ValidationMiddleware.php';

class PlanComptableController {
    private PlanComptableModel $planModel;

    public function __construct() {
        $this->planModel = new PlanComptableModel();
    }

    /** GET /api/plan-comptable */
    public function index(): void {
        $user    = AuthMiddleware::handle();
        $page    = (int)($_GET['page'] ?? 1);
        $perPage = (int)($_GET['per_page'] ?? 50);
        $filters = [
            'classe'      => $_GET['classe'] ?? null,
            'type_compte' => $_GET['type_compte'] ?? null,
            'search'      => $_GET['search'] ?? null,
        ];

        $result = $this->planModel->getAllPaginated($page, $perPage, $filters);
        ResponseHelper::paginated($result['data'], $result['total'], $page, $perPage, 'Plan comptable');
    }

    /** GET /api/plan-comptable/search */
    public function search(): void {
        AuthMiddleware::handle();
        $term = $_GET['q'] ?? '';
        if (strlen($term) < 2) ResponseHelper::error('Minimum 2 caractères', 400);

        $comptes = $this->planModel->searchComptes($term);
        ResponseHelper::success($comptes, 'Résultats de recherche');
    }

    /** GET /api/plan-comptable/arborescence */
    public function arborescence(): void {
        AuthMiddleware::handle();
        $tree = $this->planModel->getArborescence();
        ResponseHelper::success($tree, 'Arborescence du plan comptable');
    }

    /** GET /api/plan-comptable/{id} */
    public function show(int $id): void {
        AuthMiddleware::handle();
        $compte = $this->planModel->findById($id);
        if (!$compte) ResponseHelper::error('Compte introuvable', 404);

        // Ajouter le solde
        $exerciceId = $_GET['exercice_id'] ?? null;
        $compte['solde'] = $this->planModel->getSolde($id, $exerciceId ? (int)$exerciceId : null);

        ResponseHelper::success($compte, 'Compte trouvé');
    }

    /** POST /api/plan-comptable */
    public function store(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'comptabilite.create');

        $data = ValidationMiddleware::getJsonBody();

        ValidationMiddleware::make($data)
            ->required('numero_compte', 'Numéro de compte')
            ->required('libelle', 'Libellé')
            ->required('classe', 'Classe')
            ->required('type_compte', 'Type de compte')
            ->required('sens_normal', 'Sens normal')
            ->inArray('type_compte', ['ACTIF', 'PASSIF', 'CHARGE', 'PRODUIT', 'BILAN'])
            ->inArray('sens_normal', ['DEBIT', 'CREDIT'])
            ->unique('numero_compte', 'plan_comptable', 'numero_compte')
            ->validated();

        $id = $this->planModel->create([
            'numero_compte' => $data['numero_compte'],
            'libelle'       => $data['libelle'],
            'classe'        => (int)$data['classe'],
            'type_compte'   => $data['type_compte'],
            'sens_normal'   => $data['sens_normal'],
            'compte_parent' => $data['compte_parent'] ?? null,
            'is_analytique' => isset($data['is_analytique']) ? (int)$data['is_analytique'] : 0,
            'is_active'     => 1,
            'created_by'    => $user['id'],
        ]);

        $created = $this->planModel->findById($id);
        AuditHelper::log($user['id'], 'CREATE_COMPTE', 'plan_comptable', $id, null, $created);
        ResponseHelper::success($created, 'Compte créé', 201);
    }

    /** PUT /api/plan-comptable/{id} */
    public function update(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'comptabilite.update');

        $existing = $this->planModel->findById($id);
        if (!$existing) ResponseHelper::error('Compte introuvable', 404);

        $data    = ValidationMiddleware::getJsonBody();
        $allowed = ['libelle', 'is_analytique', 'is_active', 'compte_parent'];

        $updateData = [];
        foreach ($allowed as $field) {
            if (isset($data[$field])) $updateData[$field] = $data[$field];
        }

        $this->planModel->update($id, $updateData);
        $updated = $this->planModel->findById($id);

        AuditHelper::log($user['id'], 'UPDATE_COMPTE', 'plan_comptable', $id, $existing, $updateData);
        ResponseHelper::success($updated, 'Compte mis à jour');
    }

    /** DELETE /api/plan-comptable/{id} */
    public function destroy(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN', 'CHEF_COMPTABLE']);

        $existing = $this->planModel->findById($id);
        if (!$existing) ResponseHelper::error('Compte introuvable', 404);

        $solde = $this->planModel->getSolde($id);
        if ($solde['total_debit'] > 0 || $solde['total_credit'] > 0) {
            ResponseHelper::error('Impossible de supprimer un compte avec des mouvements', 400);
        }

        $this->planModel->update($id, ['is_active' => 0]);
        AuditHelper::log($user['id'], 'DELETE_COMPTE', 'plan_comptable', $id);
        ResponseHelper::success(null, 'Compte désactivé');
    }
}