import 'package:get/get.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/budget_service.dart';
import '../../core/services/caisse_service.dart';
import '../../core/services/ecriture_service.dart';
import '../../core/services/employe_service.dart';
import '../../core/services/exercice_service.dart';
import '../../core/services/facture_service.dart';
import '../../core/services/journal_service.dart';
import '../../core/services/plan_comptable_service.dart';
import '../../core/services/rapport_service.dart';
import '../../core/services/role_service.dart';
import '../../core/services/service_hopital_service.dart';
import '../../core/services/stock_service.dart';
import '../../core/services/user_service.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // ─── SERVICES (Permanent) ────────────────────────────────────
    // StorageService & ApiService already initialized in AppInitialization
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    Get.lazyPut<UserService>(() => UserService(), fenix: true);
    Get.lazyPut<RoleService>(() => RoleService(), fenix: true);
    Get.lazyPut<ServiceHopitalService>(() => ServiceHopitalService(),
        fenix: true);
    Get.lazyPut<ExerciceService>(() => ExerciceService(), fenix: true);
    Get.lazyPut<PlanComptableService>(() => PlanComptableService(),
        fenix: true);
    Get.lazyPut<JournalService>(() => JournalService(), fenix: true);
    Get.lazyPut<EcritureService>(() => EcritureService(), fenix: true);
    Get.lazyPut<BudgetService>(() => BudgetService(), fenix: true);
    Get.lazyPut<CaisseService>(() => CaisseService(), fenix: true);
    Get.lazyPut<FactureService>(() => FactureService(), fenix: true);
    Get.lazyPut<EmployeService>(() => EmployeService(), fenix: true);
    Get.lazyPut<StockService>(() => StockService(), fenix: true);
    Get.lazyPut<RapportService>(() => RapportService(), fenix: true);

    // ─── CONTROLLERS (Global) ────────────────────────────────────
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<ThemeController>(ThemeController(), permanent: true);
  }
}
