import 'package:get/get.dart';
import '../core/services/caisse_service.dart';
import '../core/utils/helpers.dart';
import '../data/models/caisse_model.dart';
import '../data/models/caisse_transaction_model.dart';

class CaisseController extends GetxController {
  final CaisseService _caisseService = Get.find<CaisseService>();

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<CaisseModel> sessions = <CaisseModel>[].obs;
  final Rx<CaisseModel?> sessionActive = Rx<CaisseModel?>(null);
  final RxList<CaisseTransactionModel> transactions = <CaisseTransactionModel>[].obs;
  final RxMap<String, dynamic> rapportData = <String, dynamic>{}.obs;

  final RxString statutFilter = ''.obs;
  final RxInt currentPage = 1.obs;

  @override
  void onInit() {
    super.onInit();
    loadSessions();
  }

  Future<void> loadSessions({bool reset = false}) async {
    if (reset) currentPage.value = 1;
    isLoading.value = true;
    try {
      final result = await _caisseService.getSessions(
        page: currentPage.value,
        statut: statutFilter.value.isEmpty ? null : statutFilter.value,
      );
      if (result['success'] == true) {
        final data = result['data'];
        sessions.assignAll(
          (data['items'] as List).map((s) => CaisseModel.fromJson(s)).toList(),
        );
        // Check for active session
        sessionActive.value = sessions.firstWhereOrNull((s) => s.isOuverte);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> ouvrirCaisse({
    required double soldeOuverture,
    String? commentaire,
  }) async {
    isSubmitting.value = true;
    try {
      final result = await _caisseService.ouvrirCaisse(
        soldeOuverture: soldeOuverture,
        commentaire: commentaire,
      );
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Caisse ouverte');
        loadSessions(reset: true);
        return true;
      } else {
        AppHelpers.showError(result['message'] ?? 'Erreur');
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> fermerCaisse(int sessionId, {
    required double soldeReel,
    String? commentaire,
  }) async {
    isSubmitting.value = true;
    try {
      final result = await _caisseService.fermerCaisse(
        sessionId,
        soldeReel: soldeReel,
        commentaire: commentaire,
      );
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Caisse fermée');
        loadSessions(reset: true);
        return true;
      } else {
        AppHelpers.showError(result['message'] ?? 'Erreur');
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> enregistrerTransaction(Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      if (sessionActive.value != null) {
        data['session_id'] = sessionActive.value!.id;
      }
      final result = await _caisseService.enregistrerTransaction(data);
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Transaction enregistrée');
        loadSessions(reset: true);
        return true;
      } else {
        AppHelpers.showError(result['message'] ?? 'Erreur');
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> loadRapport(int sessionId) async {
    isLoading.value = true;
    try {
      final result = await _caisseService.getRapportSession(sessionId);
      if (result['success'] == true) {
        rapportData.assignAll(result['data']);
      }
    } finally {
      isLoading.value = false;
    }
  }
}
