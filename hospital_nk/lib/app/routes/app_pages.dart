import 'package:get/get.dart';
import '../middlewares/auth_middleware.dart';
import 'app_routes.dart';

// Controllers
import '../../controllers/dashboard_controller.dart';
import '../../controllers/users_controller.dart';
import '../../controllers/ecriture_controller.dart';
import '../../controllers/budget_controller.dart';
import '../../controllers/caisse_controller.dart';
import '../../controllers/stock_controller.dart';
import '../../controllers/exercice_controller.dart';
import '../../controllers/facture_controller.dart';
import '../../controllers/plan_comptable_controller.dart';
import '../../controllers/employe_controller.dart';

// Views
import '../../views/splash/splash_page.dart';
import '../../views/auth/login_page.dart';
import '../../views/dashboard/dashboard_page.dart';
import '../../views/users/users_list_page.dart';
import '../../views/users/user_create_page.dart';
import '../../views/exercices/exercices_page.dart';
import '../../views/plan_comptable/plan_comptable_page.dart';
import '../../views/journaux/journaux_page.dart';
import '../../views/ecritures/ecritures_page.dart';
import '../../views/ecritures/ecriture_create_page.dart';
import '../../views/ecritures/ecriture_detail_page.dart';
import '../../views/budgets/budgets_page.dart';
import '../../views/caisse/caisse_page.dart';
import '../../views/caisse/caisse_transaction_page.dart';
import '../../views/stock/stock_page.dart';
import '../../views/factures/factures_page.dart';
import '../../views/employes/employes_page.dart';
import '../../views/rapports/rapports_page.dart';
import '../../views/profile/profile_page.dart';

class AppPages {
  static final List<GetPage> pages = [
    // ─── AUTH ─────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
    ),

    // ─── DASHBOARD ───────────────────────────────────────────────
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DashboardController());
      }),
      middlewares: [AuthMiddleware()],
    ),

    // ─── USERS (Admin only) ──────────────────────────────────────
    GetPage(
      name: AppRoutes.users,
      page: () => const UsersListPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => UsersController());
      }),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.userCreate,
      page: () => const UserCreatePage(),
      middlewares: [AuthMiddleware()],
    ),

    // ─── EXERCICES (Admin) ───────────────────────────────────────
    GetPage(
      name: AppRoutes.exercices,
      page: () => const ExercicesPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ExerciceController());
      }),
      middlewares: [AuthMiddleware()],
    ),

    // ─── PLAN COMPTABLE ──────────────────────────────────────────
    GetPage(
      name: AppRoutes.planComptable,
      page: () => const PlanComptablePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => PlanComptableController());
      }),
      middlewares: [AuthMiddleware()],
    ),

    // ─── JOURNAUX ────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.journaux,
      page: () => const JournauxPage(),
      middlewares: [AuthMiddleware()],
    ),

    // ─── ECRITURES ───────────────────────────────────────────────
    GetPage(
      name: AppRoutes.ecritures,
      page: () => const EcrituresPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => EcritureController());
      }),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.ecritureCreate,
      page: () => const EcritureCreatePage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.ecritureDetail,
      page: () => const EcritureDetailPage(),
      middlewares: [AuthMiddleware()],
    ),

    // ─── BUDGETS ─────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.budgets,
      page: () => const BudgetsPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => BudgetController());
      }),
      middlewares: [AuthMiddleware()],
    ),

    // ─── CAISSE ──────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.caisseSessions,
      page: () => const CaissePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CaisseController());
      }),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.caisseTransactions,
      page: () => const CaisseTransactionPage(),
      middlewares: [AuthMiddleware()],
    ),

    // ─── STOCK ───────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.stockProduits,
      page: () => const StockPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => StockController());
      }),
      middlewares: [AuthMiddleware()],
    ),

    // ─── FACTURES ────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.factures,
      page: () => const FacturesPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => FactureController());
      }),
      middlewares: [AuthMiddleware()],
    ),

    // ─── EMPLOYES & SALAIRES ─────────────────────────────────────
    GetPage(
      name: AppRoutes.employes,
      page: () => const EmployesPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => EmployeController());
      }),
      middlewares: [AuthMiddleware()],
    ),

    // ─── RAPPORTS ────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.rapportDashboard,
      page: () => const RapportsPage(),
      middlewares: [AuthMiddleware()],
    ),

    // ─── PROFILE ─────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfilePage(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
