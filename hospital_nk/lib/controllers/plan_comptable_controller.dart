import 'package:get/get.dart';
import '../core/services/plan_comptable_service.dart';
import '../core/utils/helpers.dart';
import '../data/models/plan_comptable_model.dart';

class PlanComptableController extends GetxController {
  final PlanComptableService _planService = Get.find<PlanComptableService>();

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<PlanComptableModel> comptes = <PlanComptableModel>[].obs;
  final RxList<Map<String, dynamic>> arborescence = <Map<String, dynamic>>[].obs;

  final RxString searchQuery = ''.obs;
  final RxInt classeFilter = 0.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;

  @override
  void onInit() {
    super.onInit();
    loadComptes();
  }

  Future<void> loadComptes({bool reset = false}) async {
    if (reset) currentPage.value = 1;
    isLoading.value = true;
    try {
      final result = await _planService.getComptes(
        page: currentPage.value,
        classe: classeFilter.value == 0 ? null : classeFilter.value,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
      );
      if (result['success'] == true) {
        final data = result['data'];
        comptes.assignAll(
          (data['items'] as List).map((c) => PlanComptableModel.fromJson(c)).toList(),
        );
        totalPages.value = data['pagination']?['last_page'] ?? 1;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadArborescence() async {
    isLoading.value = true;
    try {
      final result = await _planService.getArborescence();
      if (result['success'] == true) {
        arborescence.assignAll(List<Map<String, dynamic>>.from(result['data']));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createCompte(Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      final result = await _planService.createCompte(data);
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Compte créé');
        loadComptes(reset: true);
        return true;
      } else {
        AppHelpers.showError(result['message'] ?? 'Erreur');
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  void search(String query) {
    searchQuery.value = query;
    loadComptes(reset: true);
  }

  void filterByClasse(int? classe) {
    classeFilter.value = classe ?? 0;
    loadComptes(reset: true);
  }
}
