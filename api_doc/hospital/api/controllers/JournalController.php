<?php
// api/controllers/JournalController.php

require_once __DIR__ . '/../models/JournalModel.php';
require_once __DIR__ . '/../helpers/ResponseHelper.php';
require_once __DIR__ . '/../helpers/AuditHelper.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../middleware/RoleMiddleware.php';
require_once __DIR__ . '/../middleware/ValidationMiddleware.php';

class JournalController {
    private JournalModel $journalModel;

    public function __construct() {
        $this->journalModel = new JournalModel();
    }

    /** GET /api/journaux */
    public function index(): void {
        AuthMiddleware::handle();
        $journaux = $this->journalModel->findAllActive();
        ResponseHelper::success($journaux, 'Liste des journaux');
    }

    /** GET /api/journaux/{id} */
    public function show(int $id): void {
        AuthMiddleware::handle();
        $journal = $this->journalModel->findById($id);
        if (!$journal) ResponseHelper::error('Journal introuvable', 404);

        $exerciceId = (int)($_GET['exercice_id'] ?? 0);
        if ($exerciceId) {
            $journal['statistiques'] = $this->journalModel->getStatistiques($id, $exerciceId);
        }

        ResponseHelper::success($journal, 'Journal trouvé');
    }

    /** POST /api/journaux */
    public function store(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN', 'CHEF_COMPTABLE']);

        $data = ValidationMiddleware::getJsonBody();

        ValidationMiddleware::make($data)
            ->required('code', 'Code')
            ->required('libelle', 'Libellé')
            ->required('type', 'Type')
            ->maxLength('code', 10)
            ->inArray('type', ['VENTE', 'ACHAT', 'BANQUE', 'CAISSE', 'OD', 'SALAIRE'])
            ->unique('code', 'journaux', 'code')
            ->validated();

        $id = $this->journalModel->create([
            'code'          => strtoupper($data['code']),
            'libelle'       => $data['libelle'],
            'type'          => $data['type'],
            'compte_defaut' => $data['compte_defaut'] ?? null,
            'is_active'     => 1,
        ]);

        $created = $this->journalModel->findById($id);
        AuditHelper::log($user['id'], 'CREATE_JOURNAL', 'journaux', $id, null, $created);
        ResponseHelper::success($created, 'Journal créé', 201);
    }

    /** PUT /api/journaux/{id} */
    public function update(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN', 'CHEF_COMPTABLE']);

        $existing = $this->journalModel->findById($id);
        if (!$existing) ResponseHelper::error('Journal introuvable', 404);

        $data       = ValidationMiddleware::getJsonBody();
        $updateData = [];
        $allowed    = ['libelle', 'compte_defaut', 'is_active'];

        foreach ($allowed as $f) {
            if (isset($data[$f])) $updateData[$f] = $data[$f];
        }

        $this->journalModel->update($id, $updateData);
        AuditHelper::log($user['id'], 'UPDATE_JOURNAL', 'journaux', $id, $existing, $updateData);
        ResponseHelper::success($this->journalModel->findById($id), 'Journal mis à jour');
    }

    /** GET /api/journaux/{id}/ecritures */
    public function ecritures(int $id): void {
        AuthMiddleware::handle();

        $exerciceId = (int)($_GET['exercice_id'] ?? 0);
        if (!$exerciceId) ResponseHelper::error('exercice_id requis', 400);

        $page   = (int)($_GET['page'] ?? 1);
        $result = $this->journalModel->getEcrituresParJournal($id, $exerciceId, $page);

        ResponseHelper::paginated($result['data'], $result['total'], $page, 20, 'Écritures du journal');
    }
}