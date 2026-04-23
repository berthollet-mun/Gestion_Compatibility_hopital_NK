import 'package:get/get.dart';
import '../core/services/stock_service.dart';
import '../core/utils/helpers.dart';
import '../data/models/stock_model.dart';
import '../data/models/stock_mouvement_model.dart';

class StockController extends GetxController {
  final StockService _stockService = Get.find<StockService>();

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<StockModel> produits = <StockModel>[].obs;
  final RxList<StockMouvementModel> mouvements = <StockMouvementModel>[].obs;
  final RxMap<String, dynamic> alertesData = <String, dynamic>{}.obs;

  final RxString searchQuery = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;

  @override
  void onInit() {
    super.onInit();
    loadProduits();
    loadAlertes();
  }

  Future<void> loadProduits({bool reset = false}) async {
    if (reset) currentPage.value = 1;
    isLoading.value = true;
    try {
      final result = await _stockService.getProduits(
        page: currentPage.value,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
      );
      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map && data.containsKey('items')) {
          produits.assignAll(
            (data['items'] as List).map((p) => StockModel.fromJson(p)).toList(),
          );
          totalPages.value = data['pagination']?['last_page'] ?? 1;
        } else if (data is List) {
          produits.assignAll(data.map((p) => StockModel.fromJson(p)).toList());
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createProduit(Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      final result = await _stockService.createProduit(data);
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Produit créé');
        loadProduits(reset: true);
        return true;
      } else {
        AppHelpers.showError(result['message'] ?? 'Erreur');
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> enregistrerMouvement(Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      final result = await _stockService.enregistrerMouvement(data);
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Mouvement enregistré');
        loadProduits(reset: true);
        loadAlertes();
        return true;
      } else {
        AppHelpers.showError(result['message'] ?? 'Erreur');
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> loadMouvements({int? produitId}) async {
    isLoading.value = true;
    try {
      final result = await _stockService.getMouvements(produitId: produitId);
      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map && data.containsKey('items')) {
          mouvements.assignAll(
            (data['items'] as List).map((m) => StockMouvementModel.fromJson(m)).toList(),
          );
        } else if (data is List) {
          mouvements.assignAll(data.map((m) => StockMouvementModel.fromJson(m)).toList());
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAlertes() async {
    final result = await _stockService.getAlertes();
    if (result['success'] == true) {
      alertesData.assignAll(result['data']);
    }
  }

  int get totalAlertes => alertesData['total_alertes'] ?? 0;

  void search(String query) {
    searchQuery.value = query;
    loadProduits(reset: true);
  }
}
