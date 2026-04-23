<?php
// api/controllers/StockController.php

require_once __DIR__ . '/../models/ProduitModel.php';
require_once __DIR__ . '/../models/MouvementStockModel.php';
require_once __DIR__ . '/../helpers/ResponseHelper.php';
require_once __DIR__ . '/../helpers/AuditHelper.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../middleware/RoleMiddleware.php';
require_once __DIR__ . '/../middleware/ValidationMiddleware.php';

class StockController {
    private ProduitModel $produitModel;
    private MouvementStockModel $mouvementModel;

    public function __construct() {
        $this->produitModel   = new ProduitModel();
        $this->mouvementModel = new MouvementStockModel();
    }

    /** GET /api/stock/produits */
    public function index(): void {
        $user    = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'stock.read');

        $page    = (int)($_GET['page'] ?? 1);
        $perPage = (int)($_GET['per_page'] ?? 20);
        $filters = [
            'categorie_id' => $_GET['categorie_id'] ?? null,
            'search'       => $_GET['search'] ?? null,
            'stock_alerte' => !empty($_GET['stock_alerte']),
        ];

        $result = $this->produitModel->getAllPaginated($page, $perPage, $filters);
        ResponseHelper::paginated($result['data'], $result['total'], $page, $perPage, 'Produits');
    }

    /** GET /api/stock/produits/{id} */
    public function show(int $id): void {
        $user    = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'stock.read');

        $produit = $this->produitModel->findWithHistorique($id);
        if (!$produit) ResponseHelper::error('Produit introuvable', 404);

        ResponseHelper::success($produit, 'Produit trouvé');
    }

    /** POST /api/stock/produits */
    public function storeProduit(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'stock.create');

        $data = ValidationMiddleware::getJsonBody();

        ValidationMiddleware::make($data)
            ->required('categorie_id', 'Catégorie')
            ->required('code', 'Code')
            ->required('designation', 'Désignation')
            ->required('unite_mesure', 'Unité de mesure')
            ->unique('code', 'produits', 'code')
            ->validated();

        $id = $this->produitModel->create([
            'categorie_id'  => (int)$data['categorie_id'],
            'code'          => strtoupper($data['code']),
            'designation'   => $data['designation'],
            'unite_mesure'  => $data['unite_mesure'],
            'stock_actuel'  => (float)($data['stock_initial'] ?? 0),
            'stock_minimum' => (float)($data['stock_minimum'] ?? 0),
            'stock_maximum' => !empty($data['stock_maximum']) ? (float)$data['stock_maximum'] : null,
            'prix_unitaire' => !empty($data['prix_unitaire']) ? (float)$data['prix_unitaire'] : null,
            'compte_plan_id'=> !empty($data['compte_plan_id']) ? (int)$data['compte_plan_id'] : null,
            'is_active'     => 1,
        ]);

        $created = $this->produitModel->findById($id);
        AuditHelper::log($user['id'], 'CREATE_PRODUIT', 'produits', $id, null, $created);
        ResponseHelper::success($created, 'Produit créé', 201);
    }

    /** PUT /api/stock/produits/{id} */
    public function updateProduit(int $id): void {
        $user     = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'stock.update');

        $existing = $this->produitModel->findById($id);
        if (!$existing) ResponseHelper::error('Produit introuvable', 404);

        $data    = ValidationMiddleware::getJsonBody();
        $allowed = ['designation', 'unite_mesure', 'stock_minimum', 'stock_maximum', 'prix_unitaire', 'is_active'];
        $updateData = [];
        foreach ($allowed as $f) {
            if (isset($data[$f])) $updateData[$f] = $data[$f];
        }

        $this->produitModel->update($id, $updateData);
        AuditHelper::log($user['id'], 'UPDATE_PRODUIT', 'produits', $id, $existing, $updateData);
        ResponseHelper::success($this->produitModel->findById($id), 'Produit mis à jour');
    }

    /** POST /api/stock/mouvements */
    public function addMouvement(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'stock.create');

        $data = ValidationMiddleware::getJsonBody();

        ValidationMiddleware::make($data)
            ->required('produit_id', 'Produit')
            ->required('type', 'Type de mouvement')
            ->required('motif', 'Motif')
            ->required('quantite', 'Quantité')
            ->inArray('type', ['ENTREE', 'SORTIE', 'AJUSTEMENT', 'TRANSFERT'])
            ->numeric('quantite')
            ->positive('quantite')
            ->validated();

        try {
            $id = $this->mouvementModel->creerMouvement($data, $user['id']);
            AuditHelper::log($user['id'], 'MOUVEMENT_STOCK', 'mouvements_stock', $id, null, $data);
            ResponseHelper::success(['id' => $id], 'Mouvement de stock enregistré', 201);
        } catch (RuntimeException $e) {
            ResponseHelper::error($e->getMessage(), 400);
        }
    }

    /** GET /api/stock/mouvements */
    public function mouvements(): void {
        $user    = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'stock.read');

        $page    = (int)($_GET['page'] ?? 1);
        $perPage = (int)($_GET['per_page'] ?? 20);
        $filters = [
            'produit_id' => $_GET['produit_id'] ?? null,
            'type'       => $_GET['type'] ?? null,
            'date_debut' => $_GET['date_debut'] ?? null,
            'date_fin'   => $_GET['date_fin'] ?? null,
        ];

        $result = $this->mouvementModel->getAllPaginated($page, $perPage, $filters);
        ResponseHelper::paginated($result['data'], $result['total'], $page, $perPage, 'Mouvements de stock');
    }

    /** GET /api/stock/alertes */
    public function alertes(): void {
        $user    = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'stock.read');

        $produits = $this->produitModel->getProduitsEnAlerte();
        ResponseHelper::success($produits, 'Produits en alerte de stock');
    }

    /** GET /api/stock/valeur */
    public function valeur(): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkPermission($user, 'stock.read');

        $valeur = $this->mouvementModel->getValeurStock();
        ResponseHelper::success($valeur, 'Valeur du stock');
    }

    /** DELETE /api/stock/produits/{id} */
    public function destroyProduit(int $id): void {
        $user = AuthMiddleware::handle();
        RoleMiddleware::checkRole($user, ['SUPER_ADMIN', 'GESTIONNAIRE_STOCK']);

        $existing = $this->produitModel->findById($id);
        if (!$existing) ResponseHelper::error('Produit introuvable', 404);
        if ((float)$existing['stock_actuel'] > 0) {
            ResponseHelper::error('Impossible de supprimer un produit avec du stock restant', 400);
        }

        $this->produitModel->update($id, ['is_active' => 0]);
        AuditHelper::log($user['id'], 'DELETE_PRODUIT', 'produits', $id);
        ResponseHelper::success(null, 'Produit désactivé');
    }
}