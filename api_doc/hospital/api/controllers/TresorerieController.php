<?php
// api/controllers/TresorerieController.php

require_once __DIR__ . '/../models/CompteBancaireModel.php';
require_once __DIR__ . '/../models/MouvementBancaireModel.php';
require_once __DIR__ . '/../helpers/ResponseHelper.php';
require_once __DIR__ . '/../helpers/AuditHelper.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../middleware/RoleMiddleware.php';
require_once __DIR__ . '/../middleware/ValidationMiddleware.php';

class TresorerieController {
    private CompteBancaireModel $compteModel;
    private MouvementBancaireModel $mouvementModel;

    public function __construct() {
        $this->compteModel    = new CompteBancaireModel();
        $this->mouvementModel = new MouvementBancaireModel();
    }

    /** GET /api/tresorerie/comptes */
    public function index(): void {
        $user   = AuthMiddleware::handle();
        $comptes = $this->compteModel->findAllActive();
        ResponseHelper::success($comptes, 'Comptes bancaires');
    }

    /** GET /api/tresorerie/comptes/{id} */
    public function show(int $id): void {
        $user   = AuthMiddleware::handle();
        $page   = (int)($_GET['page'] ?? 1);
        $compte = $this->compteModel->findWithMouvements($id, $page);
        if (!$compte) ResponseHelper::error('Compte introuvable', 404);
        ResponseHelper::success($compte, 'Compte bancaire');
    }

    /** POST /api/tresorerie/comptes */
    public function store(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN', 'CHEF_COMPTABLE']);

        $data = ValidationMiddleware::getJsonBody();

        ValidationMiddleware::make($data)
            ->required('nom_banque', 'Nom de la banque')
            ->required('numero_compte', 'Numéro de compte')
            ->required('compte_plan_id', 'Compte du plan comptable')
            ->unique('numero_compte', 'comptes_bancaires', 'numero_compte')
            ->validated();

        $id = $this->compteModel->create([
            'nom_banque'     => $data['nom_banque'],
            'numero_compte'  => $data['numero_compte'],
            'iban'           => $data['iban'] ?? null,
            'devise'         => $data['devise'] ?? 'CDF',
            'solde_initial'  => (float)($data['solde_initial'] ?? 0),
            'solde_actuel'   => (float)($data['solde_initial'] ?? 0),
            'compte_plan_id' => (int)$data['compte_plan_id'],
            'is_active'      => 1,
        ]);

        $created = $this->compteModel->findById($id);
        AuditHelper::log($user['id'], 'CREATE_COMPTE_BANCAIRE', 'comptes_bancaires', $id, null, $created);
        ResponseHelper::success($created, 'Compte bancaire créé', 201);
    }

    /** PUT /api/tresorerie/comptes/{id} */
    public function update(int $id): void {
        $user     = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN', 'CHEF_COMPTABLE']);

        $existing = $this->compteModel->findById($id);
        if (!$existing) ResponseHelper::error('Compte introuvable', 404);

        $data    = ValidationMiddleware::getJsonBody();
        $allowed = ['nom_banque', 'iban', 'is_active'];
        $updateData = [];
        foreach ($allowed as $f) {
            if (isset($data[$f])) $updateData[$f] = $data[$f];
        }

        $this->compteModel->update($id, $updateData);
        AuditHelper::log($user['id'], 'UPDATE_COMPTE_BANCAIRE', 'comptes_bancaires', $id, $existing, $updateData);
        ResponseHelper::success($this->compteModel->findById($id), 'Compte mis à jour');
    }

    /** POST /api/tresorerie/mouvements */
    public function addMouvement(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN', 'CHEF_COMPTABLE', 'COMPTABLE']);

        $data = ValidationMiddleware::getJsonBody();

        ValidationMiddleware::make($data)
            ->required('compte_bancaire_id', 'Compte bancaire')
            ->required('date_operation', 'Date opération')
            ->required('libelle', 'Libellé')
            ->required('type', 'Type')
            ->required('montant', 'Montant')
            ->date('date_operation')
            ->inArray('type', ['DEBIT', 'CREDIT'])
            ->numeric('montant')
            ->positive('montant')
            ->validated();

        $compte = $this->compteModel->findById($data['compte_bancaire_id']);
        if (!$compte) ResponseHelper::error('Compte bancaire introuvable', 404);

        $montant   = (float)$data['montant'];
        $delta     = $data['type'] === 'CREDIT' ? $montant : -$montant;
        $soldeApres = (float)$compte['solde_actuel'] + $delta;

        $db = Database::getInstance();
        $db->beginTransaction();
        try {
            $sql = "INSERT INTO mouvements_bancaires
                        (compte_bancaire_id, ecriture_id, date_operation, date_valeur,
                         libelle, type, montant, solde_apres, reference)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
            $stmt = $db->prepare($sql);
            $stmt->execute([
                $data['compte_bancaire_id'],
                $data['ecriture_id'] ?? null,
                $data['date_operation'],
                $data['date_valeur'] ?? null,
                $data['libelle'],
                $data['type'],
                $montant,
                $soldeApres,
                $data['reference'] ?? null,
            ]);
            $mouvId = (int)$db->lastInsertId();

            $this->compteModel->updateSolde($data['compte_bancaire_id'], $delta);
            $db->commit();

            AuditHelper::log($user['id'], 'ADD_MOUVEMENT_BANCAIRE', 'mouvements_bancaires', $mouvId);
            ResponseHelper::success(['id' => $mouvId, 'solde_apres' => $soldeApres], 'Mouvement enregistré', 201);

        } catch (Exception $e) {
            $db->rollBack();
            ResponseHelper::error($e->getMessage(), 500);
        }
    }

    /** GET /api/tresorerie/comptes/{id}/mouvements */
    public function mouvements(int $id): void {
        AuthMiddleware::handle();

        $page    = (int)($_GET['page'] ?? 1);
        $perPage = (int)($_GET['per_page'] ?? 20);
        $filters = [
            'type'         => $_GET['type'] ?? null,
            'is_rapproche' => $_GET['is_rapproche'] ?? null,
            'date_debut'   => $_GET['date_debut'] ?? null,
            'date_fin'     => $_GET['date_fin'] ?? null,
        ];

        $result = $this->mouvementModel->getAllPaginated($id, $page, $perPage, $filters);
        ResponseHelper::paginated($result['data'], $result['total'], $page, $perPage, 'Mouvements bancaires');
    }

    /** POST /api/tresorerie/rapprochement */
    public function rapprochement(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN', 'CHEF_COMPTABLE', 'COMPTABLE']);

        $data = ValidationMiddleware::getJsonBody();
        if (empty($data['mouvement_ids']) || !is_array($data['mouvement_ids'])) {
            ResponseHelper::error('Liste des IDs de mouvements requise', 400);
        }

        $count = $this->mouvementModel->rapprocher($data['mouvement_ids']);
        AuditHelper::log($user['id'], 'RAPPROCHEMENT_BANCAIRE', 'mouvements_bancaires', null, null, $data);
        ResponseHelper::success(['nb_rapproches' => $count], "{$count} mouvement(s) rapproché(s)");
    }

    /** GET /api/tresorerie/soldes */
    public function soldes(): void {
        AuthMiddleware::handle();
        $soldes = $this->compteModel->getTotalSoldes();
        ResponseHelper::success($soldes, 'Soldes bancaires');
    }
}