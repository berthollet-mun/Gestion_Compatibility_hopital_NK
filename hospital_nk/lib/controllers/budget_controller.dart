import 'package:get/get.dart';
import '../core/services/budget_service.dart';
import '../core/services/storage_service.dart';
import '../core/utils/helpers.dart';
import '../data/models/budget_model.dart';

class BudgetController extends GetxController {
  final BudgetService _budgetService = Get.find<BudgetService>();
  final StorageService _storage = Get.find<StorageService>();

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<BudgetModel> budgets = <BudgetModel>[].obs;
  final Rx<BudgetModel?> selectedBudget = Rx<BudgetModel?>(null);

  // Execution data
  final RxMap<String, dynamic> executionData = <String, dynamic>{}.obs;

  final RxString statutFilter = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;

  @override
  void onInit() {
    super.onInit();
    loadBudgets();
  }

  Future<void> loadBudgets({bool reset = false}) async {
    if (reset) currentPage.value = 1;
    isLoading.value = true;
    try {
      final result = await _budgetService.getBudgets(
        page: currentPage.value,
        exerciceId: _storage.exerciceId,
        statut: statutFilter.value.isEmpty ? null : statutFilter.value,
      );
      if (result['success'] == true) {
        final data = result['data'];
        budgets.assignAll(
          (data['items'] as List).map((b) => BudgetModel.fromJson(b)).toList(),
        );
        totalPages.value = data['pagination']?['last_page'] ?? 1;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createBudget(Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      data['exercice_id'] = _storage.exerciceId;
      final result = await _budgetService.createBudget(data);
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Budget créé');
        loadBudgets(reset: true);
        return true;
      } else {
        AppHelpers.showError(result['message'] ?? 'Erreur');
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> approuverBudget(int id) async {
    final result = await _budgetService.approuverBudget(id);
    if (result['success'] == true) {
      AppHelpers.showSuccess('Budget approuvé');
      loadBudgets(reset: true);
      return true;
    } else {
      AppHelpers.showError(result['message'] ?? 'Erreur');
      return false;
    }
  }

  Future<void> loadExecution({int? serviceId}) async {
    isLoading.value = true;
    try {
      final result = await _budgetService.getExecution(
        exerciceId: _storage.exerciceId,
        serviceId: serviceId,
      );
      if (result['success'] == true) {
        executionData.assignAll(result['data']);
      }
    } finally {
      isLoading.value = false;
    }
  }

  void filterByStatut(String? statut) {
    statutFilter.value = statut ?? '';
    loadBudgets(reset: true);
  }
}
