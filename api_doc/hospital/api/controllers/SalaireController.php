<?php
// api/controllers/SalaireController.php

require_once __DIR__ . '/../models/BulletinSalaireModel.php';
require_once __DIR__ . '/../models/EmployeModel.php';
require_once __DIR__ . '/../helpers/ResponseHelper.php';
require_once __DIR__ . '/../helpers/AuditHelper.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../middleware/RoleMiddleware.php';
require_once __DIR__ . '/../middleware/ValidationMiddleware.php';

class SalaireController {
    private BulletinSalaireModel $bulletinModel;
    private EmployeModel $employeModel;

    public function __construct() {
        $this->bulletinModel = new BulletinSalaireModel();
        $this->employeModel  = new EmployeModel();
    }

    /** GET /api/salaires/bulletins */
    public function index(): void {
        $user    = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'paie.read');

        $page    = (int)($_GET['page'] ?? 1);
        $perPage = (int)($_GET['per_page'] ?? 20);
        $filters = [
            'employe_id' => $_GET['employe_id'] ?? null,
            'mois'       => $_GET['mois'] ?? null,
            'annee'      => $_GET['annee'] ?? null,
            'statut'     => $_GET['statut'] ?? null,
        ];

        $result = $this->bulletinModel->getAllPaginated($page, $perPage, $filters);
        ResponseHelper::paginated($result['data'], $result['total'], $page, $perPage, 'Bulletins de salaire');
    }

    /** GET /api/salaires/bulletins/{id} */
    public function show(int $id): void {
        $user    = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'paie.read');

        $bulletin = $this->bulletinModel->findWithDetails($id);
        if (!$bulletin) ResponseHelper::error('Bulletin introuvable', 404);

        ResponseHelper::success($bulletin, 'Bulletin de salaire');
    }

    /** POST /api/salaires/bulletins */
    public function store(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'paie.create');

        $data = ValidationMiddleware::getJsonBody();

        ValidationMiddleware::make($data)
            ->required('employe_id', 'Employé')
            ->required('exercice_id', 'Exercice')
            ->required('mois', 'Mois')
            ->required('annee', 'Année')
            ->numeric('mois')
            ->numeric('annee')
            ->validated();

        $mois  = (int)$data['mois'];
        $annee = (int)$data['annee'];

        if ($mois < 1 || $mois > 12) ResponseHelper::error('Mois invalide (1-12)', 400);

        // Vérifier doublon
        if ($this->bulletinModel->existsForPeriod($data['employe_id'], $mois, $annee)) {
            ResponseHelper::error("Un bulletin existe déjà pour cet employé ({$mois}/{$annee})", 400);
        }

        // Récupérer contrat actif
        $contrat = $this->employeModel->getContratActif($data['employe_id']);
        if (!$contrat) ResponseHelper::error('Aucun contrat actif pour cet employé', 400);

        $salaireBase     = (float)($data['salaire_base'] ?? $contrat['salaire_base']);
        $primeAnciennete = (float)($data['prime_anciennete'] ?? 0);
        $primeRisque     = (float)($data['prime_risque'] ?? 0);
        $autresPrimes    = (float)($data['autres_primes'] ?? 0);
        $totalBrut       = $salaireBase + $primeAnciennete + $primeRisque + $autresPrimes;

        // Calculs légaux (taux RDC)
        $cotisCnss       = round($totalBrut * 0.05, 2);   // 5% CNSS employé
        $avancesDeduites = (float)($data['avances_deduites'] ?? 0);
        $autresRetenues  = (float)($data['autres_retenues'] ?? 0);
        $ipr             = $this->calculerIPR($totalBrut);
        $totalRetenues   = $cotisCnss + $ipr + $avancesDeduites + $autresRetenues;
        $netAPayer       = $totalBrut - $totalRetenues;

        $id = $this->bulletinModel->create([
            'employe_id'       => (int)$data['employe_id'],
            'contrat_id'       => $contrat['id'],
            'exercice_id'      => (int)$data['exercice_id'],
            'mois'             => $mois,
            'annee'            => $annee,
            'salaire_base'     => $salaireBase,
            'prime_anciennete' => $primeAnciennete,
            'prime_risque'     => $primeRisque,
            'autres_primes'    => $autresPrimes,
            'total_brut'       => $totalBrut,
            'cotis_cnss'       => $cotisCnss,
            'ipr'              => $ipr,
            'avances_deduites' => $avancesDeduites,
            'autres_retenues'  => $autresRetenues,
            'total_retenues'   => $totalRetenues,
            'net_a_payer'      => $netAPayer,
            'statut'           => 'BROUILLON',
        ]);

        $created = $this->bulletinModel->findWithDetails($id);
        AuditHelper::log($user['id'], 'CREATE_BULLETIN', 'bulletins_salaire', $id, null, $created);
        ResponseHelper::success($created, 'Bulletin créé', 201);
    }

    /** PUT /api/salaires/bulletins/{id}/valider */
    public function valider(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'paie.validate');

        $bulletin = $this->bulletinModel->findById($id);
        if (!$bulletin) ResponseHelper::error('Bulletin introuvable', 404);
        if ($bulletin['statut'] !== 'BROUILLON') {
            ResponseHelper::error('Ce bulletin ne peut plus être validé', 400);
        }

        $this->bulletinModel->update($id, [
            'statut'     => 'VALIDE',
            'valide_par' => $user['id'],
            'valide_le'  => date('Y-m-d H:i:s'),
        ]);

        AuditHelper::log($user['id'], 'VALIDER_BULLETIN', 'bulletins_salaire', $id);
        ResponseHelper::success($this->bulletinModel->findWithDetails($id), 'Bulletin validé');
    }

    /** PUT /api/salaires/bulletins/{id}/payer */
    public function payer(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'paie.validate');

        $bulletin = $this->bulletinModel->findById($id);
        if (!$bulletin) ResponseHelper::error('Bulletin introuvable', 404);
        if ($bulletin['statut'] !== 'VALIDE') {
            ResponseHelper::error('Seuls les bulletins validés peuvent être marqués comme payés', 400);
        }

        $this->bulletinModel->update($id, ['statut' => 'PAYE']);
        AuditHelper::log($user['id'], 'PAYER_BULLETIN', 'bulletins_salaire', $id);
        ResponseHelper::success(null, 'Bulletin marqué comme payé');
    }

    /** GET /api/salaires/masse-mensuelle */
    public function masseMensuelle(): void {
        $user  = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'paie.read');

        $mois  = (int)($_GET['mois'] ?? date('m'));
        $annee = (int)($_GET['annee'] ?? date('Y'));

        $data = $this->bulletinModel->getMasseSalarialeMensuelle($mois, $annee);
        ResponseHelper::success($data, "Masse salariale {$mois}/{$annee}");
    }

    /** DELETE /api/salaires/bulletins/{id} */
    public function destroy(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN', 'CHEF_COMPTABLE']);

        $bulletin = $this->bulletinModel->findById($id);
        if (!$bulletin) ResponseHelper::error('Bulletin introuvable', 404);
        if ($bulletin['statut'] !== 'BROUILLON') {
            ResponseHelper::error('Seuls les brouillons peuvent être supprimés', 400);
        }

        $this->bulletinModel->delete($id);
        AuditHelper::log($user['id'], 'DELETE_BULLETIN', 'bulletins_salaire', $id);
        ResponseHelper::success(null, 'Bulletin supprimé');
    }

    private function calculerIPR(float $brut): float {
        // Barème IPR simplifié RDC (à adapter selon la réglementation en vigueur)
        return match(true) {
            $brut <= 50000  => 0,
            $brut <= 100000 => round($brut * 0.03, 2),
            $brut <= 200000 => round($brut * 0.08, 2),
            $brut <= 500000 => round($brut * 0.13, 2),
            default          => round($brut * 0.20, 2),
        };
    }
}