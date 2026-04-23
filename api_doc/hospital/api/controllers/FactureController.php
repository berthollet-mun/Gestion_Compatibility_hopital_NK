<?php
// api/controllers/FactureController.php

require_once __DIR__ . '/../models/FactureModel.php';
require_once __DIR__ . '/../models/FournisseurModel.php';
require_once __DIR__ . '/../helpers/ResponseHelper.php';
require_once __DIR__ . '/../helpers/AuditHelper.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../middleware/RoleMiddleware.php';
require_once __DIR__ . '/../middleware/ValidationMiddleware.php';

class FactureController {
    private FactureModel $factureModel;
    private FournisseurModel $fournisseurModel;

    public function __construct() {
        $this->factureModel     = new FactureModel();
        $this->fournisseurModel = new FournisseurModel();
    }

    /** GET /api/factures */
    public function index(): void {
        $user    = AuthMiddleware::handle();
        $page    = (int)($_GET['page'] ?? 1);
        $perPage = (int)($_GET['per_page'] ?? 20);
        $filters = [
            'type'           => $_GET['type'] ?? null,
            'statut'         => $_GET['statut'] ?? null,
            'fournisseur_id' => $_GET['fournisseur_id'] ?? null,
            'date_debut'     => $_GET['date_debut'] ?? null,
            'date_fin'       => $_GET['date_fin'] ?? null,
        ];

        $result = $this->factureModel->getAllPaginated($page, $perPage, $filters);
        ResponseHelper::paginated($result['data'], $result['total'], $page, $perPage, 'Factures');
    }

    /** GET /api/factures/{id} */
    public function show(int $id): void {
        AuthMiddleware::handle();
        $facture = $this->factureModel->findWithLignes($id);
        if (!$facture) ResponseHelper::error('Facture introuvable', 404);
        ResponseHelper::success($facture, 'Facture trouvée');
    }

    /** POST /api/factures */
    public function store(): void {
        $user = AuthMiddleware::handle();

        $data = ValidationMiddleware::getJsonBody();

        ValidationMiddleware::make($data)
            ->required('type', 'Type de facture')
            ->required('nom_client', 'Nom du client')
            ->required('date_facture', 'Date de facture')
            ->required('lignes', 'Lignes de facture')
            ->inArray('type', ['CLIENT', 'FOURNISSEUR', 'AVOIR'])
            ->date('date_facture')
            ->validated();

        if (empty($data['lignes'])) {
            ResponseHelper::error('Au moins une ligne est requise', 400);
        }

        // Calculer les totaux
        $montantHT = 0;
        foreach ($data['lignes'] as $ligne) {
            $montantHT += (float)($ligne['quantite'] ?? 1) * (float)($ligne['prix_unitaire'] ?? 0)
                          * (1 - (float)($ligne['remise_pct'] ?? 0) / 100);
        }

        $tauxTva    = (float)($data['taux_tva'] ?? 0);
        $montantTva = round($montantHT * ($tauxTva / 100), 2);
        $montantTtc = round($montantHT + $montantTva, 2);

        $db = Database::getInstance();
        $db->beginTransaction();
        try {
            $numero = $this->factureModel->generateNumero($data['type']);

            $factureId = $this->factureModel->create([
                'numero'         => $numero,
                'type'           => $data['type'],
                'date_facture'   => $data['date_facture'],
                'date_echeance'  => $data['date_echeance'] ?? null,
                'patient_ref'    => $data['patient_ref'] ?? null,
                'nom_client'     => $data['nom_client'],
                'fournisseur_id' => !empty($data['fournisseur_id']) ? (int)$data['fournisseur_id'] : null,
                'montant_ht'     => round($montantHT, 2),
                'taux_tva'       => $tauxTva,
                'montant_tva'    => $montantTva,
                'montant_ttc'    => $montantTtc,
                'montant_paye'   => 0,
                'statut'         => 'EMISE',
                'cree_par'       => $user['id'],
            ]);

            // Insérer les lignes
            $sqlLigne = "INSERT INTO lignes_facture
                            (facture_id, tarif_acte_id, produit_id, designation, quantite, prix_unitaire, remise_pct)
                         VALUES (?, ?, ?, ?, ?, ?, ?)";
            $stmtL = $db->prepare($sqlLigne);

            foreach ($data['lignes'] as $ligne) {
                $stmtL->execute([
                    $factureId,
                    $ligne['tarif_acte_id'] ?? null,
                    $ligne['produit_id'] ?? null,
                    $ligne['designation'],
                    (float)($ligne['quantite'] ?? 1),
                    (float)$ligne['prix_unitaire'],
                    (float)($ligne['remise_pct'] ?? 0),
                ]);
            }

            $db->commit();
            $created = $this->factureModel->findWithLignes($factureId);
            AuditHelper::log($user['id'], 'CREATE_FACTURE', 'factures', $factureId, null, $created);
            ResponseHelper::success($created, 'Facture créée', 201);

        } catch (Exception $e) {
            $db->rollBack();
            ResponseHelper::error($e->getMessage(), 500);
        }
    }

    /** POST /api/factures/{id}/paiement */
    public function enregistrerPaiement(int $id): void {
        $user = AuthMiddleware::handle();
        $data = ValidationMiddleware::getJsonBody();

        ValidationMiddleware::make($data)
            ->required('montant', 'Montant du paiement')
            ->numeric('montant')
            ->positive('montant')
            ->validated();

        try {
            $result = $this->factureModel->enregistrerPaiement($id, (float)$data['montant']);
            AuditHelper::log($user['id'], 'PAIEMENT_FACTURE', 'factures', $id, null, $data);
            ResponseHelper::success($result, 'Paiement enregistré');
        } catch (RuntimeException $e) {
            ResponseHelper::error($e->getMessage(), 400);
        }
    }

    /** PUT /api/factures/{id}/annuler */
    public function annuler(int $id): void {
        $user    = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN', 'CHEF_COMPTABLE']);

        $facture = $this->factureModel->findById($id);
        if (!$facture) ResponseHelper::error('Facture introuvable', 404);
        if ($facture['statut'] === 'PAYEE') {
            ResponseHelper::error('Impossible d\'annuler une facture entièrement payée', 400);
        }

        $this->factureModel->update($id, ['statut' => 'ANNULEE']);
        AuditHelper::log($user['id'], 'ANNULER_FACTURE', 'factures', $id);
        ResponseHelper::success(null, 'Facture annulée');
    }

    /** GET /api/factures/echues */
    public function echues(): void {
        AuthMiddleware::handle();
        $factures = $this->factureModel->getFacturesEchues();
        ResponseHelper::success($factures, 'Factures échues');
    }

    /** GET /api/fournisseurs */
    public function indexFournisseurs(): void {
        AuthMiddleware::handle();
        $page    = (int)($_GET['page'] ?? 1);
        $perPage = (int)($_GET['per_page'] ?? 20);
        $filters = ['search' => $_GET['search'] ?? null];

        $result = $this->fournisseurModel->getAllPaginated($page, $perPage, $filters);
        ResponseHelper::paginated($result['data'], $result['total'], $page, $perPage, 'Fournisseurs');
    }

    /** GET /api/fournisseurs/{id} */
    public function showFournisseur(int $id): void {
        AuthMiddleware::handle();
        $fournisseur = $this->fournisseurModel->findWithFactures($id);
        if (!$fournisseur) ResponseHelper::error('Fournisseur introuvable', 404);
        ResponseHelper::success($fournisseur, 'Fournisseur trouvé');
    }

    /** POST /api/fournisseurs */
    public function storeFournisseur(): void {
        $user = AuthMiddleware::handle();
        $data = ValidationMiddleware::getJsonBody();

        ValidationMiddleware::make($data)
            ->required('nom', 'Nom du fournisseur')
            ->validated();

        $id = $this->fournisseurModel->create([
            'nom'                  => $data['nom'],
            'numero_rccm'          => $data['numero_rccm'] ?? null,
            'numero_impot'         => $data['numero_impot'] ?? null,
            'telephone'            => $data['telephone'] ?? null,
            'email'                => $data['email'] ?? null,
            'adresse'              => $data['adresse'] ?? null,
            'conditions_paiement'  => (int)($data['conditions_paiement'] ?? 30),
            'compte_plan_id'       => !empty($data['compte_plan_id']) ? (int)$data['compte_plan_id'] : null,
            'is_active'            => 1,
        ]);

        AuditHelper::log($user['id'], 'CREATE_FOURNISSEUR', 'fournisseurs', $id);
        ResponseHelper::success($this->fournisseurModel->findById($id), 'Fournisseur créé', 201);
    }

    /** PUT /api/fournisseurs/{id} */
    public function updateFournisseur(int $id): void {
        $user     = AuthMiddleware::handle();
        $existing = $this->fournisseurModel->findById($id);
        if (!$existing) ResponseHelper::error('Fournisseur introuvable', 404);

        $data    = ValidationMiddleware::getJsonBody();
        $allowed = ['nom', 'numero_rccm', 'numero_impot', 'telephone', 'email', 'adresse', 'conditions_paiement', 'is_active'];
        $updateData = [];
        foreach ($allowed as $f) {
            if (isset($data[$f])) $updateData[$f] = $data[$f];
        }

        $this->fournisseurModel->update($id, $updateData);
        AuditHelper::log($user['id'], 'UPDATE_FOURNISSEUR', 'fournisseurs', $id, $existing, $updateData);
        ResponseHelper::success($this->fournisseurModel->findById($id), 'Fournisseur mis à jour');
    }
}