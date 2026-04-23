import 'package:get/get.dart';
import '../core/services/rapport_service.dart';
import '../core/services/storage_service.dart';

class DashboardController extends GetxController {
  final RapportService _rapportService = Get.find<RapportService>();
  final StorageService _storage = Get.find<StorageService>();

  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // KPIs
  final RxDouble totalRecettes = 0.0.obs;
  final RxDouble totalDepenses = 0.0.obs;
  final RxDouble resultatNet = 0.0.obs;
  final RxDouble tauxExecutionBudget = 0.0.obs;
  final RxInt nbEcrituresEnAttente = 0.obs;
  final RxDouble soldeCaisse = 0.0.obs;
  final RxDouble soldeBanque = 0.0.obs;

  // Evolution mensuelle
  final RxList<Map<String, dynamic>> evolutionMensuelle =
      <Map<String, dynamic>>[].obs;

  // Top charges
  final RxList<Map<String, dynamic>> topCharges = <Map<String, dynamic>>[].obs;

  // Alertes
  final RxList<Map<String, dynamic>> alertes = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final exerciceId = _storage.exerciceId;
      final result = await _rapportService.getDashboard(exerciceId: exerciceId);

      if (result['success'] == true) {
        final data = result['data'];
        final kpi = data['kpi'] ?? {};

        totalRecettes.value = (kpi['total_recettes'] ?? 0).toDouble();
        totalDepenses.value = (kpi['total_depenses'] ?? 0).toDouble();
        resultatNet.value = (kpi['resultat_net'] ?? 0).toDouble();
        tauxExecutionBudget.value =
            (kpi['taux_execution_budget'] ?? 0).toDouble();
        nbEcrituresEnAttente.value = kpi['nb_ecritures_en_attente'] ?? 0;
        soldeCaisse.value = (kpi['solde_caisse'] ?? 0).toDouble();
        soldeBanque.value = (kpi['solde_banque'] ?? 0).toDouble();

        evolutionMensuelle.assignAll(
          List<Map<String, dynamic>>.from(data['evolution_mensuelle'] ?? []),
        );
        topCharges.assignAll(
          List<Map<String, dynamic>>.from(data['top_comptes_charges'] ?? []),
        );
        alertes.assignAll(
          List<Map<String, dynamic>>.from(data['alertes'] ?? []),
        );
      } else {
        hasError.value = true;
        errorMessage.value = result['message'] ?? 'Erreur chargement dashboard';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Erreur de connexion au serveur';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await loadDashboard();
  }
}
