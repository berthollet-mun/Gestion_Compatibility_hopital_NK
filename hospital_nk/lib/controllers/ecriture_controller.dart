import 'package:get/get.dart';
import '../core/services/ecriture_service.dart';
import '../core/services/journal_service.dart';
import '../core/services/plan_comptable_service.dart';
import '../core/services/storage_service.dart';
import '../core/utils/helpers.dart';
import '../data/models/ecriture_model.dart';
import '../data/models/journal_model.dart';
import '../data/models/plan_comptable_model.dart';

class EcritureController extends GetxController {
  final EcritureService _ecritureService = Get.find<EcritureService>();
  final JournalService _journalService = Get.find<JournalService>();
  final PlanComptableService _planService = Get.find<PlanComptableService>();
  final StorageService _storage = Get.find<StorageService>();

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<EcritureModel> ecritures = <EcritureModel>[].obs;
  final Rx<EcritureModel?> selectedEcriture = Rx<EcritureModel?>(null);
  final RxList<JournalModel> journaux = <JournalModel>[].obs;
  final RxList<PlanComptableModel> comptes = <PlanComptableModel>[].obs;

  // Filters
  final RxString statutFilter = ''.obs;
  final RxInt journalFilter = 0.obs;
  final RxString searchQuery = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;

  @override
  void onInit() {
    super.onInit();
    loadEcritures();
    loadJournaux();
    loadComptes();
  }

  Future<void> loadEcritures({bool reset = false}) async {
    if (reset) {
      currentPage.value = 1;
      ecritures.clear();
    }
    isLoading.value = true;
    try {
      final result = await _ecritureService.getEcritures(
        page: currentPage.value,
        exerciceId: _storage.exerciceId,
        statut: statutFilter.value.isEmpty ? null : statutFilter.value,
        journalId: journalFilter.value == 0 ? null : journalFilter.value,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
      );
      if (result['success'] == true) {
        final data = result['data'];
        ecritures.assignAll(
          (data['items'] as List).map((e) => EcritureModel.fromJson(e)).toList(),
        );
        final pagination = data['pagination'];
        totalPages.value = pagination['last_page'] ?? 1;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadJournaux() async {
    final result = await _journalService.getJournaux();
    if (result['success'] == true) {
      journaux.assignAll(
        (result['data'] as List).map((j) => JournalModel.fromJson(j)).toList(),
      );
    }
  }

  Future<void> loadComptes() async {
    final result = await _planService.getComptes(perPage: 200, actif: true);
    if (result['success'] == true) {
      comptes.assignAll(
        (result['data']['items'] as List).map((c) => PlanComptableModel.fromJson(c)).toList(),
      );
    }
  }

  Future<void> loadEcriture(int id) async {
    isLoading.value = true;
    try {
      final result = await _ecritureService.getEcriture(id);
      if (result['success'] == true) {
        selectedEcriture.value = EcritureModel.fromJson(result['data']);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createEcriture(Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      data['exercice_id'] = _storage.exerciceId;
      final result = await _ecritureService.createEcriture(data);
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Écriture créée');
        loadEcritures(reset: true);
        return true;
      } else {
        AppHelpers.showError(result['message'] ?? 'Erreur');
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> soumettreEcriture(int id) async {
    final result = await _ecritureService.soumettreEcriture(id);
    if (result['success'] == true) {
      AppHelpers.showSuccess('Écriture soumise');
      loadEcritures(reset: true);
      return true;
    } else {
      AppHelpers.showError(result['message'] ?? 'Erreur');
      return false;
    }
  }

  Future<bool> validerEcriture(int id, {String? commentaire}) async {
    final result = await _ecritureService.validerEcriture(id, commentaire: commentaire);
    if (result['success'] == true) {
      AppHelpers.showSuccess('Écriture validée');
      loadEcritures(reset: true);
      return true;
    } else {
      AppHelpers.showError(result['message'] ?? 'Erreur');
      return false;
    }
  }

  Future<bool> rejeterEcriture(int id, {required String commentaire}) async {
    final result = await _ecritureService.rejeterEcriture(id, commentaire: commentaire);
    if (result['success'] == true) {
      AppHelpers.showSuccess('Écriture rejetée');
      loadEcritures(reset: true);
      return true;
    } else {
      AppHelpers.showError(result['message'] ?? 'Erreur');
      return false;
    }
  }

  void filterByStatut(String? statut) {
    statutFilter.value = statut ?? '';
    loadEcritures(reset: true);
  }

  void filterByJournal(int? journalId) {
    journalFilter.value = journalId ?? 0;
    loadEcritures(reset: true);
  }

  void search(String query) {
    searchQuery.value = query;
    loadEcritures(reset: true);
  }
}
