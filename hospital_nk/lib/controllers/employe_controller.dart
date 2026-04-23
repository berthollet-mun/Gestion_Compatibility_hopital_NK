import 'package:get/get.dart';
import '../core/services/employe_service.dart';
import '../core/utils/helpers.dart';
import '../data/models/employe_model.dart';
import '../data/models/bulletin_salaire_model.dart';

class EmployeController extends GetxController {
  final EmployeService _employeService = Get.find<EmployeService>();

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<EmployeModel> employes = <EmployeModel>[].obs;
  final RxList<BulletinSalaireModel> bulletins = <BulletinSalaireModel>[].obs;
  final Rx<EmployeModel?> selectedEmploye = Rx<EmployeModel?>(null);

  final RxString searchQuery = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;

  @override
  void onInit() {
    super.onInit();
    loadEmployes();
  }

  Future<void> loadEmployes({bool reset = false}) async {
    if (reset) currentPage.value = 1;
    isLoading.value = true;
    try {
      final result = await _employeService.getEmployes(
        page: currentPage.value,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
      );
      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map && data.containsKey('items')) {
          employes.assignAll(
            (data['items'] as List).map((e) => EmployeModel.fromJson(e)).toList(),
          );
          totalPages.value = data['pagination']?['last_page'] ?? 1;
        } else if (data is List) {
          employes.assignAll(data.map((e) => EmployeModel.fromJson(e)).toList());
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createEmploye(Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      final result = await _employeService.createEmploye(data);
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Employé créé');
        loadEmployes(reset: true);
        return true;
      } else {
        AppHelpers.showError(result['message'] ?? 'Erreur');
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateEmploye(int id, Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      final result = await _employeService.updateEmploye(id, data);
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Mis à jour');
        loadEmployes(reset: true);
        return true;
      } else {
        AppHelpers.showError(result['message'] ?? 'Erreur');
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─── BULLETINS ─────────────────────────────────────────────────
  Future<void> loadBulletins({int? mois, int? annee}) async {
    isLoading.value = true;
    try {
      final result = await _employeService.getBulletins(mois: mois, annee: annee);
      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map && data.containsKey('items')) {
          bulletins.assignAll(
            (data['items'] as List).map((b) => BulletinSalaireModel.fromJson(b)).toList(),
          );
        } else if (data is List) {
          bulletins.assignAll(data.map((b) => BulletinSalaireModel.fromJson(b)).toList());
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createBulletin(Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      final result = await _employeService.createBulletin(data);
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Bulletin créé');
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
    loadEmployes(reset: true);
  }
}
