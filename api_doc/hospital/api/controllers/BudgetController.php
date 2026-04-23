<?php
// api/controllers/BudgetController.php

require_once __DIR__ . '/../models/BudgetModel.php';
require_once __DIR__ . '/../helpers/ResponseHelper.php';
require_once __DIR__ . '/../helpers/AuditHelper.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../middleware/RoleMiddleware.php';
require_once __DIR__ . '/../middleware/ValidationMiddleware.php';

class BudgetController {
    private BudgetModel $budgetModel;

    public function __construct() {
        $this->budgetModel = new BudgetModel();
    }

    /** GET /api/budgets */
    public function index(): void {
        $user    = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'budget.read');

        $page    = (int)($_GET['page'] ?? 1);
        $perPage = (int)($_GET['per_page'] ?? 20);
        $filters = [
            'exercice_id' => $_GET['exercice_id'] ?? null,
            'service_id'  => $_GET['service_id'] ?? null,
            'statut'      => $_GET['statut'] ?? null,
        ];

        $result = $this->budgetModel->getAllPaginated($page, $perPage, $filters);
        ResponseHelper::paginated($result['data'], $result['total'], $page, $perPage, 'Budgets');
    }

    /** GET /api/budgets/{id} */
    public function show(int $id): void {
        $user   = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'budget.read');

        $budget = $this->budgetModel->findWithDetails($id);
        if (!$budget) ResponseHelper::error('Budget introuvable', 404);

        ResponseHelper::success($budget, 'Budget trouvé');
    }

    /** POST /api/budgets */
    public function store(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'budget.create');

        $data = ValidationMiddleware::getJsonBody();

        ValidationMiddleware::make($data)
            ->required('exercice_id', 'Exercice')
            ->required('service_id', 'Service')
            ->required('compte_id', 'Compte')
            ->required('montant_prevu', 'Montant prévu')
            ->numeric('montant_prevu')
            ->positive('montant_prevu')
            ->validated();

        $id = $this->budgetModel->create([
            'exercice_id'  => (int)$data['exercice_id'],
            'service_id'   => (int)$data['service_id'],
            'compte_id'    => (int)$data['compte_id'],
            'montant_prevu'=> (float)$data['montant_prevu'],
            'description'  => $data['description'] ?? null,
            'statut'       => 'DRAFT',
            'soumis_par'   => $user['id'],
        ]);

        $created = $this->budgetModel->findWithDetails($id);
        AuditHelper::log($user['id'], 'CREATE_BUDGET', 'budgets', $id, null, $created);
        ResponseHelper::success($created, 'Budget créé', 201);
    }

    /** PUT /api/budgets/{id} */
    public function update(int $id): void {
        $user   = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'budget.create');

        $budget = $this->budgetModel->findById($id);
        if (!$budget) ResponseHelper::error('Budget introuvable', 404);
        if ($budget['statut'] !== 'DRAFT') {
            ResponseHelper::error('Seuls les budgets en DRAFT peuvent être modifiés', 400);
        }

        $data    = ValidationMiddleware::getJsonBody();
        $allowed = ['montant_prevu', 'description'];
        $updateData = [];
        foreach ($allowed as $f) {
            if (isset($data[$f])) $updateData[$f] = $data[$f];
        }

        $this->budgetModel->update($id, $updateData);
        AuditHelper::log($user['id'], 'UPDATE_BUDGET', 'budgets', $id, $budget, $updateData);
        ResponseHelper::success($this->budgetModel->findWithDetails($id), 'Budget mis à jour');
    }

    /** PUT /api/budgets/{id}/soumettre */
    public function soumettre(int $id): void {
        $user   = AuthMiddleware::handle();
        $budget = $this->budgetModel->findById($id);
        if (!$budget) ResponseHelper::error('Budget introuvable', 404);
        if ($budget['soumis_par'] != $user['id']) {
            ResponseHelper::error('Vous ne pouvez soumettre que vos propres budgets', 403);
        }
        if ($budget['statut'] !== 'DRAFT') {
            ResponseHelper::error('Seuls les budgets DRAFT peuvent être soumis', 400);
        }

        $this->budgetModel->update($id, ['statut' => 'SOUMIS']);
        AuditHelper::log($user['id'], 'SOUMETTRE_BUDGET', 'budgets', $id);
        ResponseHelper::success(null, 'Budget soumis pour approbation');
    }

    /** PUT /api/budgets/{id}/approuver */
    public function approuver(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'budget.approve');

        $budget = $this->budgetModel->findById($id);
        if (!$budget) ResponseHelper::error('Budget introuvable', 404);
        if ($budget['statut'] !== 'SOUMIS') {
            ResponseHelper::error('Seuls les budgets SOUMIS peuvent être approuvés', 400);
        }

        $this->budgetModel->update($id, [
            'statut'      => 'APPROUVE',
            'approuve_par'=> $user['id'],
            'approuve_le' => date('Y-m-d H:i:s'),
        ]);

        AuditHelper::log($user['id'], 'APPROUVER_BUDGET', 'budgets', $id);
        ResponseHelper::success($this->budgetModel->findWithDetails($id), 'Budget approuvé');
    }

    /** PUT /api/budgets/{id}/rejeter */
    public function rejeter(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'budget.approve');

        $budget = $this->budgetModel->findById($id);
        if (!$budget) ResponseHelper::error('Budget introuvable', 404);

        $this->budgetModel->update($id, ['statut' => 'REJETE']);
        AuditHelper::log($user['id'], 'REJETER_BUDGET', 'budgets', $id);
        ResponseHelper::success(null, 'Budget rejeté');
    }

    /** GET /api/budgets/execution */
    public function execution(): void {
        $user       = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'budget.read');

        $exerciceId = (int)($_GET['exercice_id'] ?? 0);
        $serviceId  = (int)($_GET['service_id'] ?? 0);

        if (!$exerciceId || !$serviceId) {
            ResponseHelper::error('exercice_id et service_id sont requis', 400);
        }

        $taux = $this->budgetModel->getTauxExecution($exerciceId, $serviceId);
        ResponseHelper::success($taux, 'Taux d\'exécution budgétaire');
    }

    /** DELETE /api/budgets/{id} */
    public function destroy(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN', 'CHEF_COMPTABLE']);

        $budget = $this->budgetModel->findById($id);
        if (!$budget) ResponseHelper::error('Budget introuvable', 404);
        if ($budget['statut'] === 'APPROUVE') {
            ResponseHelper::error('Impossible de supprimer un budget approuvé', 400);
        }

        $this->budgetModel->delete($id);
        AuditHelper::log($user['id'], 'DELETE_BUDGET', 'budgets', $id);
        ResponseHelper::success(null, 'Budget supprimé');
    }
}