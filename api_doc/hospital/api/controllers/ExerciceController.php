<?php
// api/controllers/ExerciceController.php

require_once __DIR__ . '/../models/ExerciceModel.php';
require_once __DIR__ . '/../helpers/ResponseHelper.php';
require_once __DIR__ . '/../helpers/AuditHelper.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../middleware/RoleMiddleware.php';
require_once __DIR__ . '/../middleware/ValidationMiddleware.php';

class ExerciceController {
    private ExerciceModel $exerciceModel;

    public function __construct() {
        $this->exerciceModel = new ExerciceModel();
    }

    /** GET /api/exercices */
    public function index(): void {
        $user      = AuthMiddleware::handle();
        $exercices = $this->exerciceModel->findAllWithStats();
        ResponseHelper::success($exercices, 'Liste des exercices fiscaux');
    }

    /** GET /api/exercices/current */
    public function current(): void {
        AuthMiddleware::handle();
        $exercice = $this->exerciceModel->findCurrent();
        if (!$exercice) ResponseHelper::error('Aucun exercice ouvert', 404);
        ResponseHelper::success($exercice, 'Exercice en cours');
    }

    /** GET /api/exercices/{id} */
    public function show(int $id): void {
        AuthMiddleware::handle();
        $exercice = $this->exerciceModel->findById($id);
        if (!$exercice) ResponseHelper::error('Exercice introuvable', 404);
        ResponseHelper::success($exercice, 'Exercice trouvé');
    }

    /** POST /api/exercices */
    public function store(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN', 'CHEF_COMPTABLE']);

        $data = ValidationMiddleware::getJsonBody();

        ValidationMiddleware::make($data)
            ->required('annee', 'Année')
            ->required('date_debut', 'Date de début')
            ->required('date_fin', 'Date de fin')
            ->numeric('annee')
            ->date('date_debut')
            ->date('date_fin')
            ->unique('annee', 'exercices_fiscaux', 'annee')
            ->validated();

        if ($data['date_debut'] >= $data['date_fin']) {
            ResponseHelper::error('La date de début doit être avant la date de fin', 400);
        }

        $id = $this->exerciceModel->create([
            'annee'      => (int)$data['annee'],
            'date_debut' => $data['date_debut'],
            'date_fin'   => $data['date_fin'],
            'statut'     => 'OUVERT',
        ]);

        $created = $this->exerciceModel->findById($id);
        AuditHelper::log($user['id'], 'CREATE_EXERCICE', 'exercices_fiscaux', $id, null, $created);
        ResponseHelper::success($created, 'Exercice créé', 201);
    }

    /** PUT /api/exercices/{id}/cloturer */
    public function cloturer(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN', 'CHEF_COMPTABLE']);

        $data     = ValidationMiddleware::getJsonBody();
        $exercice = $this->exerciceModel->findById($id);

        if (!$exercice) ResponseHelper::error('Exercice introuvable', 404);
        if ($exercice['statut'] === 'CLOTURE_DEF') {
            ResponseHelper::error('Cet exercice est déjà clôturé définitivement', 400);
        }

        $type = $data['type'] ?? 'temporaire';

        if ($type === 'definitif') {
            $this->exerciceModel->cloturerDefinitivement($id, $user['id']);
            $msg = 'Exercice clôturé définitivement';
        } else {
            $this->exerciceModel->cloturerTemporairement($id, $user['id']);
            $msg = 'Exercice clôturé temporairement';
        }

        AuditHelper::log($user['id'], 'CLOTURER_EXERCICE', 'exercices_fiscaux', $id, $exercice, ['type' => $type]);
        ResponseHelper::success($this->exerciceModel->findById($id), $msg);
    }

    /** PUT /api/exercices/{id}/rouvrir */
    public function rouvrir(int $id): void {
        $user     = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN']);

        $exercice = $this->exerciceModel->findById($id);
        if (!$exercice) ResponseHelper::error('Exercice introuvable', 404);
        if ($exercice['statut'] === 'CLOTURE_DEF') {
            ResponseHelper::error('Un exercice clôturé définitivement ne peut pas être rouvert', 403);
        }

        $this->exerciceModel->rouvrir($id);
        AuditHelper::log($user['id'], 'ROUVRIR_EXERCICE', 'exercices_fiscaux', $id);
        ResponseHelper::success(null, 'Exercice rouvert');
    }
}