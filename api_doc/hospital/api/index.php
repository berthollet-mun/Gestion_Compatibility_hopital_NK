<?php
// api/index.php

// ══════════════════════════════════════════════════════════════
// PROTECTION CONTRE LES ERREURS PHP GÉNÉRANT DU HTML
// ══════════════════════════════════════════════════════════════
error_reporting(E_ALL);
ini_set('display_errors', '0');
ini_set('log_errors', '1');
ini_set('html_errors', '0');

// ══════════════════════════════════════════════════════════════
// MODE LOCAL XAMPP
// ══════════════════════════════════════════════════════════════
// Aucun contournement d'hebergeur n'est necessaire en local.

// ══════════════════════════════════════════════════════════════
// FORCER LES HEADERS JSON AVANT TOUT OUTPUT
// ══════════════════════════════════════════════════════════════
// Nettoyer tout buffer existant
if (ob_get_level()) {
    ob_end_clean();
}
ob_start();

header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept');
header('X-Robots-Tag: noindex');
header('X-Content-Type-Options: nosniff');

// Désactiver la mise en cache
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');

// ══════════════════════════════════════════════════════════════
// GESTIONNAIRE D'ERREURS FATALES (shutdown)
// ══════════════════════════════════════════════════════════════
register_shutdown_function(function () {
    $error = error_get_last();
    if ($error && in_array($error['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR])) {
        // Nettoyer tout output HTML potentiel
        if (ob_get_level()) {
            ob_end_clean();
        }
        header('Content-Type: application/json; charset=UTF-8');
        http_response_code(500);
        echo json_encode([
            'success'   => false,
            'message'   => 'Erreur fatale du serveur',
            'debug'     => defined('APP_DEBUG') && APP_DEBUG
                           ? $error['message'] . ' in ' . $error['file'] . ':' . $error['line']
                           : null,
            'timestamp' => date('Y-m-d H:i:s'),
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }
});

// ══════════════════════════════════════════════════════════════
// GESTIONNAIRE D'ERREURS PHP (warnings, notices → ne pas afficher)
// ══════════════════════════════════════════════════════════════
set_error_handler(function ($severity, $message, $file, $line) {
    // Logger l'erreur au lieu de l'afficher
    error_log("PHP [{$severity}]: {$message} in {$file}:{$line}");
    // Ne PAS afficher — évite que du texte/HTML se mélange au JSON
    return true;
});

// ══════════════════════════════════════════════════════════════
// CHARGEMENT DES DÉPENDANCES
// ══════════════════════════════════════════════════════════════
try {
    // --- Config & DB ---
    require_once __DIR__ . '/config/Config.php';
    require_once __DIR__ . '/config/Database.php';
    require_once __DIR__ . '/config/Cors.php';

    // --- Helpers ---
    require_once __DIR__ . '/helpers/ResponseHelper.php';
    require_once __DIR__ . '/helpers/JwtHelper.php';
    require_once __DIR__ . '/helpers/PasswordHelper.php';
    require_once __DIR__ . '/helpers/AuditHelper.php';

    // --- Middleware ---
    require_once __DIR__ . '/middleware/AuthMiddleware.php';
    require_once __DIR__ . '/middleware/RoleMiddleware.php';
    require_once __DIR__ . '/middleware/ValidationMiddleware.php';

    // ─── Modèles ──────────────────────────────────────────────────
    require_once __DIR__ . '/models/BaseModel.php';
    require_once __DIR__ . '/models/UserModel.php';
    require_once __DIR__ . '/models/RoleModel.php';
    require_once __DIR__ . '/models/ServiceModel.php';
    require_once __DIR__ . '/models/ExerciceModel.php';
    require_once __DIR__ . '/models/PlanComptableModel.php';
    require_once __DIR__ . '/models/JournalModel.php';
    require_once __DIR__ . '/models/EcritureModel.php';
    require_once __DIR__ . '/models/BudgetModel.php';
    require_once __DIR__ . '/models/CaisseModel.php';
    require_once __DIR__ . '/models/SessionCaisseModel.php';
    require_once __DIR__ . '/models/TransactionCaisseModel.php';
    require_once __DIR__ . '/models/CompteBancaireModel.php';
    require_once __DIR__ . '/models/MouvementBancaireModel.php';
    require_once __DIR__ . '/models/EmployeModel.php';
    require_once __DIR__ . '/models/BulletinSalaireModel.php';
    require_once __DIR__ . '/models/ProduitModel.php';
    require_once __DIR__ . '/models/MouvementStockModel.php';
    require_once __DIR__ . '/models/FournisseurModel.php';
    require_once __DIR__ . '/models/FactureModel.php';

    // ─── Contrôleurs ──────────────────────────────────────────────
    require_once __DIR__ . '/controllers/AuthController.php';
    require_once __DIR__ . '/controllers/UserController.php';
    require_once __DIR__ . '/controllers/RoleController.php';
    require_once __DIR__ . '/controllers/ServiceController.php';
    require_once __DIR__ . '/controllers/ExerciceController.php';
    require_once __DIR__ . '/controllers/PlanComptableController.php';
    require_once __DIR__ . '/controllers/JournalController.php';
    require_once __DIR__ . '/controllers/EcritureController.php';
    require_once __DIR__ . '/controllers/BudgetController.php';
    require_once __DIR__ . '/controllers/CaisseController.php';
    require_once __DIR__ . '/controllers/TresorerieController.php';
    require_once __DIR__ . '/controllers/EmployeController.php';
    require_once __DIR__ . '/controllers/SalaireController.php';
    require_once __DIR__ . '/controllers/StockController.php';
    require_once __DIR__ . '/controllers/FactureController.php';
    require_once __DIR__ . '/controllers/RapportController.php';
    require_once __DIR__ . '/routes/Router.php';

} catch (Throwable $e) {
    if (ob_get_level()) ob_end_clean();
    http_response_code(500);
    echo json_encode([
        'success'   => false,
        'message'   => 'Erreur de chargement des dépendances',
        'debug'     => $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine(),
        'timestamp' => date('Y-m-d H:i:s'),
    ], JSON_UNESCAPED_UNICODE);
    exit();
}

// ══════════════════════════════════════════════════════════════
// GESTION CORS
// ══════════════════════════════════════════════════════════════
Cors::handle();

// ══════════════════════════════════════════════════════════════
// GESTIONNAIRE D'EXCEPTIONS GLOBAL
// ══════════════════════════════════════════════════════════════
set_exception_handler(function (Throwable $e) {
    if (ob_get_level()) ob_end_clean();
    ResponseHelper::error(
        Config::get('APP_DEBUG') === 'true' ? $e->getMessage() : 'Erreur interne du serveur',
        500
    );
});

// ══════════════════════════════════════════════════════════════
// ENREGISTREMENT DES ROUTES
// ══════════════════════════════════════════════════════════════
$router = new Router();

// ══════════════════════════════════════════════════════════════
// AUTH
// ══════════════════════════════════════════════════════════════
$router->post('/auth/login',           fn() => (new AuthController())->login());
$router->post('/auth/logout',          fn() => (new AuthController())->logout());
$router->post('/auth/refresh',         fn() => (new AuthController())->refresh());
$router->post('/auth/change-password', fn() => (new AuthController())->changePassword());
$router->get( '/auth/me',              fn() => (new AuthController())->me());

// ══════════════════════════════════════════════════════════════
// UTILISATEURS
// ══════════════════════════════════════════════════════════════
$router->get(   '/users',                      fn() => (new UserController())->index());
$router->post(  '/users',                      fn() => (new UserController())->store());
$router->get(   '/users/{id}',                 fn($id) => (new UserController())->show((int)$id));
$router->put(   '/users/{id}',                 fn($id) => (new UserController())->update((int)$id));
$router->delete('/users/{id}',                 fn($id) => (new UserController())->destroy((int)$id));
$router->post(  '/users/{id}/reset-password',  fn($id) => (new UserController())->resetPassword((int)$id));

// ══════════════════════════════════════════════════════════════
// RÔLES & PERMISSIONS
// ══════════════════════════════════════════════════════════════
$router->get(   '/roles',               fn() => (new RoleController())->index());
$router->post(  '/roles',               fn() => (new RoleController())->store());
$router->get(   '/roles/permissions',   fn() => (new RoleController())->allPermissions());
$router->get(   '/roles/{id}',          fn($id) => (new RoleController())->show((int)$id));
$router->put(   '/roles/{id}',          fn($id) => (new RoleController())->update((int)$id));
$router->delete('/roles/{id}',          fn($id) => (new RoleController())->destroy((int)$id));

// ══════════════════════════════════════════════════════════════
// SERVICES
// ══════════════════════════════════════════════════════════════
$router->get(   '/services',            fn() => (new ServiceController())->index());
$router->post(  '/services',            fn() => (new ServiceController())->store());
$router->get(   '/services/{id}',       fn($id) => (new ServiceController())->show((int)$id));
$router->put(   '/services/{id}',       fn($id) => (new ServiceController())->update((int)$id));
$router->delete('/services/{id}',       fn($id) => (new ServiceController())->destroy((int)$id));
$router->get(   '/services/{id}/budget',fn($id) => (new ServiceController())->budget((int)$id));

// ══════════════════════════════════════════════════════════════
// EXERCICES FISCAUX
// ══════════════════════════════════════════════════════════════
$router->get('/exercices',                  fn() => (new ExerciceController())->index());
$router->post('/exercices',                 fn() => (new ExerciceController())->store());
$router->get('/exercices/current',          fn() => (new ExerciceController())->current());
$router->get('/exercices/{id}',             fn($id) => (new ExerciceController())->show((int)$id));
$router->put('/exercices/{id}/cloturer',    fn($id) => (new ExerciceController())->cloturer((int)$id));
$router->put('/exercices/{id}/rouvrir',     fn($id) => (new ExerciceController())->rouvrir((int)$id));

// ══════════════════════════════════════════════════════════════
// PLAN COMPTABLE
// ══════════════════════════════════════════════════════════════
$router->get(   '/plan-comptable',                fn() => (new PlanComptableController())->index());
$router->post(  '/plan-comptable',                fn() => (new PlanComptableController())->store());
$router->get(   '/plan-comptable/search',         fn() => (new PlanComptableController())->search());
$router->get(   '/plan-comptable/arborescence',   fn() => (new PlanComptableController())->arborescence());
$router->get(   '/plan-comptable/{id}',           fn($id) => (new PlanComptableController())->show((int)$id));
$router->put(   '/plan-comptable/{id}',           fn($id) => (new PlanComptableController())->update((int)$id));
$router->delete('/plan-comptable/{id}',           fn($id) => (new PlanComptableController())->destroy((int)$id));

// ══════════════════════════════════════════════════════════════
// JOURNAUX
// ══════════════════════════════════════════════════════════════
$router->get( '/journaux',                  fn() => (new JournalController())->index());
$router->post('/journaux',                  fn() => (new JournalController())->store());
$router->get( '/journaux/{id}',             fn($id) => (new JournalController())->show((int)$id));
$router->put( '/journaux/{id}',             fn($id) => (new JournalController())->update((int)$id));
$router->get( '/journaux/{id}/ecritures',   fn($id) => (new JournalController())->ecritures((int)$id));

// ══════════════════════════════════════════════════════════════
// ÉCRITURES COMPTABLES
// ══════════════════════════════════════════════════════════════
$router->get( '/ecritures',                    fn() => (new EcritureController())->index());
$router->post('/ecritures',                    fn() => (new EcritureController())->store());
$router->get( '/ecritures/{id}',               fn($id) => (new EcritureController())->show((int)$id));
$router->put( '/ecritures/{id}/soumettre',     fn($id) => (new EcritureController())->soumettre((int)$id));
$router->put( '/ecritures/{id}/valider',       fn($id) => (new EcritureController())->valider((int)$id));
$router->put( '/ecritures/{id}/rejeter',       fn($id) => (new EcritureController())->rejeter((int)$id));

// ══════════════════════════════════════════════════════════════
// BUDGET
// ══════════════════════════════════════════════════════════════
$router->get(   '/budgets',                   fn() => (new BudgetController())->index());
$router->post(  '/budgets',                   fn() => (new BudgetController())->store());
$router->get(   '/budgets/execution',         fn() => (new BudgetController())->execution());
$router->get(   '/budgets/{id}',              fn($id) => (new BudgetController())->show((int)$id));
$router->put(   '/budgets/{id}',              fn($id) => (new BudgetController())->update((int)$id));
$router->put(   '/budgets/{id}/soumettre',    fn($id) => (new BudgetController())->soumettre((int)$id));
$router->put(   '/budgets/{id}/approuver',    fn($id) => (new BudgetController())->approuver((int)$id));
$router->put(   '/budgets/{id}/rejeter',      fn($id) => (new BudgetController())->rejeter((int)$id));
$router->delete('/budgets/{id}',              fn($id) => (new BudgetController())->destroy((int)$id));

// ══════════════════════════════════════════════════════════════
// CAISSE
// ══════════════════════════════════════════════════════════════
$router->get( '/caisse/sessions',                   fn() => (new CaisseController())->getSessions());
$router->post('/caisse/ouvrir',                     fn() => (new CaisseController())->ouvrirSession());
$router->post('/caisse/transactions',               fn() => (new CaisseController())->addTransaction());
$router->put( '/caisse/sessions/{id}/fermer',       fn($id) => (new CaisseController())->fermerSession((int)$id));
$router->get( '/caisse/sessions/{id}/rapport',      fn($id) => (new CaisseController())->rapportSession((int)$id));

// ══════════════════════════════════════════════════════════════
// TRÉSORERIE
// ══════════════════════════════════════════════════════════════
$router->get( '/tresorerie/comptes',                    fn() => (new TresorerieController())->index());
$router->post('/tresorerie/comptes',                    fn() => (new TresorerieController())->store());
$router->get( '/tresorerie/comptes/{id}',               fn($id) => (new TresorerieController())->show((int)$id));
$router->put( '/tresorerie/comptes/{id}',               fn($id) => (new TresorerieController())->update((int)$id));
$router->get( '/tresorerie/comptes/{id}/mouvements',    fn($id) => (new TresorerieController())->mouvements((int)$id));
$router->post('/tresorerie/mouvements',                 fn() => (new TresorerieController())->addMouvement());
$router->post('/tresorerie/rapprochement',              fn() => (new TresorerieController())->rapprochement());
$router->get( '/tresorerie/soldes',                     fn() => (new TresorerieController())->soldes());

// ══════════════════════════════════════════════════════════════
// EMPLOYÉS
// ══════════════════════════════════════════════════════════════
$router->get(   '/employes',                     fn() => (new EmployeController())->index());
$router->post(  '/employes',                     fn() => (new EmployeController())->store());
$router->get(   '/employes/masses-salariales',   fn() => (new EmployeController())->massesSalariales());
$router->get(   '/employes/{id}',                fn($id) => (new EmployeController())->show((int)$id));
$router->put(   '/employes/{id}',                fn($id) => (new EmployeController())->update((int)$id));
$router->delete('/employes/{id}',                fn($id) => (new EmployeController())->destroy((int)$id));

// ══════════════════════════════════════════════════════════════
// SALAIRES
// ══════════════════════════════════════════════════════════════
$router->get(   '/salaires/bulletins',                  fn() => (new SalaireController())->index());
$router->post(  '/salaires/bulletins',                  fn() => (new SalaireController())->store());
$router->get(   '/salaires/masse-mensuelle',             fn() => (new SalaireController())->masseMensuelle());
$router->get(   '/salaires/bulletins/{id}',             fn($id) => (new SalaireController())->show((int)$id));
$router->put(   '/salaires/bulletins/{id}/valider',     fn($id) => (new SalaireController())->valider((int)$id));
$router->put(   '/salaires/bulletins/{id}/payer',       fn($id) => (new SalaireController())->payer((int)$id));
$router->delete('/salaires/bulletins/{id}',             fn($id) => (new SalaireController())->destroy((int)$id));

// ══════════════════════════════════════════════════════════════
// STOCK
// ══════════════════════════════════════════════════════════════
$router->get(   '/stock/produits',          fn() => (new StockController())->index());
$router->post(  '/stock/produits',          fn() => (new StockController())->storeProduit());
$router->get(   '/stock/produits/alertes',  fn() => (new StockController())->alertes());
$router->get(   '/stock/produits/valeur',   fn() => (new StockController())->valeur());
$router->get(   '/stock/produits/{id}',     fn($id) => (new StockController())->show((int)$id));
$router->put(   '/stock/produits/{id}',     fn($id) => (new StockController())->updateProduit((int)$id));
$router->delete('/stock/produits/{id}',     fn($id) => (new StockController())->destroyProduit((int)$id));
$router->get(   '/stock/mouvements',        fn() => (new StockController())->mouvements());
$router->post(  '/stock/mouvements',        fn() => (new StockController())->addMouvement());

// ══════════════════════════════════════════════════════════════
// FACTURES & FOURNISSEURS
// ══════════════════════════════════════════════════════════════
$router->get( '/factures',                   fn() => (new FactureController())->index());
$router->post('/factures',                   fn() => (new FactureController())->store());
$router->get( '/factures/echues',            fn() => (new FactureController())->echues());
$router->get( '/factures/{id}',              fn($id) => (new FactureController())->show((int)$id));
$router->post('/factures/{id}/paiement',     fn($id) => (new FactureController())->enregistrerPaiement((int)$id));
$router->put( '/factures/{id}/annuler',      fn($id) => (new FactureController())->annuler((int)$id));
$router->get( '/fournisseurs',               fn() => (new FactureController())->indexFournisseurs());
$router->post('/fournisseurs',               fn() => (new FactureController())->storeFournisseur());
$router->get( '/fournisseurs/{id}',          fn($id) => (new FactureController())->showFournisseur((int)$id));
$router->put( '/fournisseurs/{id}',          fn($id) => (new FactureController())->updateFournisseur((int)$id));

// ══════════════════════════════════════════════════════════════
// RAPPORTS
// ══════════════════════════════════════════════════════════════
$router->get('/rapports/dashboard',    fn() => (new RapportController())->dashboard());
$router->get('/rapports/grand-livre',  fn() => (new RapportController())->grandLivre());
$router->get('/rapports/balance',      fn() => (new RapportController())->balance());

// ══════════════════════════════════════════════════════════════
// DISPATCH
// ══════════════════════════════════════════════════════════════
$router->dispatch();

// Flush output buffer
if (ob_get_level()) {
    ob_end_flush();
}