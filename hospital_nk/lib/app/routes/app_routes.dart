abstract class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const dashboard = '/dashboard';

  // Users
  static const users = '/users';
  static const userCreate = '/users/create';
  static const userDetail = '/users/detail';
  static const userEdit = '/users/edit';

  // Roles
  static const roles = '/roles';
  static const roleCreate = '/roles/create';

  // Services
  static const services = '/services';
  static const serviceCreate = '/services/create';
  static const serviceBudget = '/services/budget';

  // Exercices
  static const exercices = '/exercices';
  static const exerciceCreate = '/exercices/create';

  // Plan Comptable
  static const planComptable = '/plan-comptable';
  static const compteCreate = '/plan-comptable/create';
  static const planArborescence = '/plan-comptable/arborescence';

  // Journaux
  static const journaux = '/journaux';
  static const journalCreate = '/journaux/create';
  static const journalEcritures = '/journaux/ecritures';

  // Ecritures
  static const ecritures = '/ecritures';
  static const ecritureCreate = '/ecritures/create';
  static const ecritureDetail = '/ecritures/detail';

  // Budget
  static const budgets = '/budgets';
  static const budgetCreate = '/budgets/create';
  static const budgetExecution = '/budgets/execution';

  // Caisse
  static const caisseSessions = '/caisse/sessions';
  static const caisseOuvrir = '/caisse/ouvrir';
  static const caisseTransactions = '/caisse/transactions';
  static const caisseRapport = '/caisse/rapport';

  // Rapports
  static const rapportDashboard = '/rapports/dashboard';
  static const rapportGrandLivre = '/rapports/grand-livre';
  static const rapportBalance = '/rapports/balance';

  // Tresorerie
  static const tresorerieMovements = '/tresorerie/mouvements';
  static const tresorerieRapprochement = '/tresorerie/rapprochement';

  // Stock
  static const stockProduits = '/stock/produits';
  static const stockProduitCreate = '/stock/produits/create';
  static const stockMovements = '/stock/mouvements';
  static const stockAlertes = '/stock/alertes';

  // Factures
  static const factures = '/factures';
  static const factureCreate = '/factures/create';
  static const facturePaiement = '/factures/paiement';

  // Employes
  static const employes = '/employes';
  static const employeCreate = '/employes/create';

  // Salaires
  static const salaires = '/salaires';
  static const salaireBulletin = '/salaires/bulletin';

  // Profile
  static const profile = '/profile';
  static const changePassword = '/profile/change-password';
}