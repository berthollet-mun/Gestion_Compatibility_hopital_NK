<?php
// api/controllers/EcritureController.php

require_once __DIR__ . '/../models/EcritureModel.php';
require_once __DIR__ . '/../helpers/ResponseHelper.php';
require_once __DIR__ . '/../helpers/AuditHelper.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../middleware/RoleMiddleware.php';
require_once __DIR__ . '/../middleware/ValidationMiddleware.php';

class EcritureController {
    private EcritureModel $ecritureModel;

    public function __construct() {
        $this->ecritureModel = new EcritureModel();
    }

    /** GET /api/ecritures */
    public function index(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'comptabilite.read');

        $page    = (int) ($_GET['page'] ?? 1);
        $perPage = (int) ($_GET['per_page'] ?? 20);
        $filters = [
            'exercice_id' => $_GET['exercice_id'] ?? null,
            'journal_id'  => $_GET['journal_id'] ?? null,
            'statut'      => $_GET['statut'] ?? null,
            'date_debut'  => $_GET['date_debut'] ?? null,
            'date_fin'    => $_GET['date_fin'] ?? null,
        ];

        $result = $this->ecritureModel->getAllPaginated($page, $perPage, $filters);

        ResponseHelper::paginated(
            $result['data'], $result['total'], $page, $perPage, 'Écritures comptables'
        );
    }

    /** GET /api/ecritures/{id} */
    public function show(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'comptabilite.read');

        $ecriture = $this->ecritureModel->findWithLignes($id);
        if (!$ecriture) {
            ResponseHelper::error('Écriture introuvable', 404);
        }

        ResponseHelper::success($ecriture, 'Écriture trouvée');
    }

    /** POST /api/ecritures */
    public function store(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'comptabilite.create');

        $data = ValidationMiddleware::getJsonBody();

        ValidationMiddleware::make($data)
            ->required('exercice_id', 'Exercice')
            ->required('journal_id', 'Journal')
            ->required('date_ecriture', 'Date d\'écriture')
            ->required('libelle', 'Libellé')
            ->required('lignes', 'Lignes d\'écriture')
            ->date('date_ecriture')
            ->validated();

        if (empty($data['lignes']) || count($data['lignes']) < 2) {
            ResponseHelper::error('Une écriture doit avoir au minimum 2 lignes', 400);
        }

        // Vérifier l'équilibre débit/crédit
        if (!$this->ecritureModel->isEquilibree($data['lignes'])) {
            $totalD = array_sum(array_column($data['lignes'], 'debit'));
            $totalC = array_sum(array_column($data['lignes'], 'credit'));
            ResponseHelper::error(
                "L'écriture n'est pas équilibrée. Débit: {$totalD} / Crédit: {$totalC}",
                400
            );
        }

        $ecritureData = [
            'exercice_id'   => (int)$data['exercice_id'],
            'journal_id'    => (int)$data['journal_id'],
            'date_ecriture' => $data['date_ecriture'],
            'date_valeur'   => $data['date_valeur'] ?? null,
            'libelle'       => $data['libelle'],
            'statut'        => 'BROUILLON',
            'reference_ext' => $data['reference_ext'] ?? null,
        ];

        $ecritureId = $this->ecritureModel->creerAvecLignes($ecritureData, $data['lignes'], $user['id']);
        $created    = $this->ecritureModel->findWithLignes($ecritureId);

        AuditHelper::log($user['id'], 'CREATE_ECRITURE', 'ecritures_comptables', $ecritureId, null, $created);
        ResponseHelper::success($created, 'Écriture créée avec succès', 201);
    }

    /** PUT /api/ecritures/{id}/valider */
    public function valider(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'comptabilite.validate');

        $ecriture = $this->ecritureModel->findById($id);
        if (!$ecriture) {
            ResponseHelper::error('Écriture introuvable', 404);
        }

        if (!in_array($ecriture['statut'], ['BROUILLON', 'SOUMIS'])) {
            ResponseHelper::error("Impossible de valider une écriture en statut : {$ecriture['statut']}", 400);
        }

        // Empêcher l'auto-validation
        if ($ecriture['saisi_par'] == $user['id']) {
            ResponseHelper::error('Vous ne pouvez pas valider votre propre écriture', 403);
        }

        $this->ecritureModel->update($id, [
            'statut'     => 'VALIDE',
            'valide_par' => $user['id'],
            'valide_le'  => date('Y-m-d H:i:s'),
        ]);

        AuditHelper::log($user['id'], 'VALIDER_ECRITURE', 'ecritures_comptables', $id, $ecriture, ['statut' => 'VALIDE']);
        ResponseHelper::success(
            $this->ecritureModel->findWithLignes($id),
            'Écriture validée avec succès'
        );
    }

    /** PUT /api/ecritures/{id}/rejeter */
    public function rejeter(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'comptabilite.validate');

        $data     = ValidationMiddleware::getJsonBody();
        $ecriture = $this->ecritureModel->findById($id);

        if (!$ecriture) {
            ResponseHelper::error('Écriture introuvable', 404);
        }

        if ($ecriture['statut'] !== 'SOUMIS') {
            ResponseHelper::error('Seules les écritures soumises peuvent être rejetées', 400);
        }

        $motif = $data['motif'] ?? 'Aucun motif fourni';

        $this->ecritureModel->update($id, [
            'statut'       => 'REJETE',
            'motif_rejet'  => $motif,
            'valide_par'   => $user['id'],
        ]);

        AuditHelper::log($user['id'], 'REJETER_ECRITURE', 'ecritures_comptables', $id);
        ResponseHelper::success(null, 'Écriture rejetée');
    }

    /** PUT /api/ecritures/{id}/soumettre */
    public function soumettre(int $id): void {
        $user     = AuthMiddleware::handle();
        $ecriture = $this->ecritureModel->findById($id);

        if (!$ecriture) {
            ResponseHelper::error('Écriture introuvable', 404);
        }

        if ($ecriture['saisi_par'] != $user['id']) {
            ResponseHelper::error('Vous ne pouvez soumettre que vos propres écritures', 403);
        }

        if ($ecriture['statut'] !== 'BROUILLON') {
            ResponseHelper::error('Seuls les brouillons peuvent être soumis', 400);
        }

        $this->ecritureModel->update($id, ['statut' => 'SOUMIS']);
        AuditHelper::log($user['id'], 'SOUMETTRE_ECRITURE', 'ecritures_comptables', $id);
        ResponseHelper::success(null, 'Écriture soumise pour validation');
    }
}