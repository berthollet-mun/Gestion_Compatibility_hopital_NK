<?php
// api/controllers/EmployeController.php

require_once __DIR__ . '/../models/EmployeModel.php';
require_once __DIR__ . '/../helpers/ResponseHelper.php';
require_once __DIR__ . '/../helpers/AuditHelper.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../middleware/RoleMiddleware.php';
require_once __DIR__ . '/../middleware/ValidationMiddleware.php';

class EmployeController {
    private EmployeModel $employeModel;

    public function __construct() {
        $this->employeModel = new EmployeModel();
    }

    /** GET /api/employes */
    public function index(): void {
        $user    = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'paie.read');

        $page    = (int)($_GET['page'] ?? 1);
        $perPage = (int)($_GET['per_page'] ?? 20);
        $filters = [
            'service_id' => $_GET['service_id'] ?? null,
            'statut'     => $_GET['statut'] ?? null,
            'search'     => $_GET['search'] ?? null,
        ];

        $result = $this->employeModel->getAllPaginated($page, $perPage, $filters);
        ResponseHelper::paginated($result['data'], $result['total'], $page, $perPage, 'Liste des employés');
    }

    /** GET /api/employes/{id} */
    public function show(int $id): void {
        $user    = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'paie.read');

        $employe = $this->employeModel->findWithContrats($id);
        if (!$employe) ResponseHelper::error('Employé introuvable', 404);

        ResponseHelper::success($employe, 'Employé trouvé');
    }

    /** POST /api/employes */
    public function store(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'paie.create');

        $data = ValidationMiddleware::getJsonBody();

        ValidationMiddleware::make($data)
            ->required('matricule', 'Matricule')
            ->required('nom', 'Nom')
            ->required('prenom', 'Prénom')
            ->required('service_id', 'Service')
            ->required('date_embauche', 'Date d\'embauche')
            ->date('date_embauche')
            ->unique('matricule', 'employes', 'matricule')
            ->validated();

        $db = Database::getInstance();
        $db->beginTransaction();
        try {
            $empId = $this->employeModel->create([
                'service_id'      => (int)$data['service_id'],
                'matricule'       => strtoupper($data['matricule']),
                'nom'             => strtoupper($data['nom']),
                'prenom'          => ucwords(strtolower($data['prenom'])),
                'date_naissance'  => $data['date_naissance'] ?? null,
                'sexe'            => $data['sexe'] ?? null,
                'nationalite'     => $data['nationalite'] ?? 'Congolaise',
                'numero_cnss'     => $data['numero_cnss'] ?? null,
                'numero_inss'     => $data['numero_inss'] ?? null,
                'telephone'       => $data['telephone'] ?? null,
                'adresse'         => $data['adresse'] ?? null,
                'date_embauche'   => $data['date_embauche'],
                'statut'          => 'ACTIF',
            ]);

            // Créer le contrat si fourni
            if (!empty($data['contrat'])) {
                $c = $data['contrat'];
                ValidationMiddleware::make($c)
                    ->required('type_contrat', 'Type de contrat')
                    ->required('poste', 'Poste')
                    ->required('salaire_base', 'Salaire de base')
                    ->required('date_debut', 'Date de début du contrat')
                    ->validated();

                $db->prepare(
                    "INSERT INTO contrats
                        (employe_id, type_contrat, poste, categorie, salaire_base,
                         date_debut, date_fin, is_actif, signe_par)
                     VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)"
                )->execute([
                    $empId,
                    $c['type_contrat'],
                    $c['poste'],
                    $c['categorie'] ?? null,
                    (float)$c['salaire_base'],
                    $c['date_debut'],
                    $c['date_fin'] ?? null,
                    $user['id'],
                ]);
            }

            $db->commit();
            $created = $this->employeModel->findWithContrats($empId);
            AuditHelper::log($user['id'], 'CREATE_EMPLOYE', 'employes', $empId, null, $created);
            ResponseHelper::success($created, 'Employé créé', 201);

        } catch (Exception $e) {
            $db->rollBack();
            ResponseHelper::error($e->getMessage(), 500);
        }
    }

    /** PUT /api/employes/{id} */
    public function update(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'paie.create');

        $existing = $this->employeModel->findById($id);
        if (!$existing) ResponseHelper::error('Employé introuvable', 404);

        $data    = ValidationMiddleware::getJsonBody();
        $allowed = ['nom', 'prenom', 'telephone', 'adresse', 'service_id', 'statut', 'numero_cnss', 'numero_inss'];
        $updateData = [];
        foreach ($allowed as $f) {
            if (isset($data[$f])) $updateData[$f] = $data[$f];
        }

        $this->employeModel->update($id, $updateData);
        AuditHelper::log($user['id'], 'UPDATE_EMPLOYE', 'employes', $id, $existing, $updateData);
        ResponseHelper::success($this->employeModel->findWithContrats($id), 'Employé mis à jour');
    }

    /** DELETE /api/employes/{id} */
    public function destroy(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN', 'CHEF_COMPTABLE']);

        $existing = $this->employeModel->findById($id);
        if (!$existing) ResponseHelper::error('Employé introuvable', 404);

        $this->employeModel->update($id, ['statut' => 'DEMISSIONNE']);
        AuditHelper::log($user['id'], 'DESACTIVER_EMPLOYE', 'employes', $id);
        ResponseHelper::success(null, 'Employé désactivé');
    }

    /** GET /api/employes/masses-salariales */
    public function massesSalariales(): void {
        $user       = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'paie.read');
        $exerciceId = (int)($_GET['exercice_id'] ?? 0);
        if (!$exerciceId) ResponseHelper::error('exercice_id requis', 400);

        $data = $this->employeModel->getMassesSalariales($exerciceId);
        ResponseHelper::success($data, 'Masses salariales par service');
    }
}