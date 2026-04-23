import 'package:get/get.dart';
import '../core/services/facture_service.dart';
import '../core/services/storage_service.dart';
import '../core/utils/helpers.dart';
import '../data/models/facture_model.dart';

class FactureController extends GetxController {
  final FactureService _factureService = Get.find<FactureService>();
  final StorageService _storage = Get.find<StorageService>();

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<FactureModel> factures = <FactureModel>[].obs;
  final Rx<FactureModel?> selectedFacture = Rx<FactureModel?>(null);

  final RxString typeFilter = ''.obs;
  final RxString statutFilter = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;

  @override
  void onInit() {
    super.onInit();
    loadFactures();
  }

  Future<void> loadFactures({bool reset = false}) async {
    if (reset) currentPage.value = 1;
    isLoading.value = true;
    try {
      final result = await _factureService.getFactures(
        page: currentPage.value,
        type: typeFilter.value.isEmpty ? null : typeFilter.value,
        statut: statutFilter.value.isEmpty ? null : statutFilter.value,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        exerciceId: _storage.exerciceId,
      );
      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map && data.containsKey('items')) {
          factures.assignAll(
            (data['items'] as List).map((f) => FactureModel.fromJson(f)).toList(),
          );
          totalPages.value = data['pagination']?['last_page'] ?? 1;
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createFacture(Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      data['exercice_id'] = _storage.exerciceId;
      final result = await _factureService.createFacture(data);
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Facture créée');
        loadFactures(reset: true);
        return true;
      } else {
        AppHelpers.showError(result['message'] ?? 'Erreur');
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> enregistrerPaiement(int factureId, Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      final result = await _factureService.enregistrerPaiement(factureId, data);
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Paiement enregistré');
        loadFactures(reset: true);
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
    loadFactures(reset: true);
  }
}
