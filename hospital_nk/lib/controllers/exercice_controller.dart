import 'package:get/get.dart';
import '../core/services/exercice_service.dart';
import '../core/services/storage_service.dart';
import '../core/utils/helpers.dart';
import '../data/models/exercice_model.dart';

class ExerciceController extends GetxController {
  final ExerciceService _exerciceService = Get.find<ExerciceService>();
  final StorageService _storage = Get.find<StorageService>();

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<ExerciceModel> exercices = <ExerciceModel>[].obs;
  final Rx<ExerciceModel?> currentExercice = Rx<ExerciceModel?>(null);

  @override
  void onInit() {
    super.onInit();
    loadExercices();
    loadCurrentExercice();
  }

  Future<void> loadExercices() async {
    isLoading.value = true;
    try {
      final result = await _exerciceService.getExercices();
      if (result['success'] == true) {
        exercices.assignAll(
          (result['data'] as List).map((e) => ExerciceModel.fromJson(e)).toList(),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCurrentExercice() async {
    final result = await _exerciceService.getCurrentExercice();
    if (result['success'] == true) {
      currentExercice.value = ExerciceModel.fromJson(result['data']);
      await _storage.saveExerciceId(currentExercice.value!.id);
    }
  }

  Future<bool> createExercice(Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      final result = await _exerciceService.createExercice(data);
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Exercice créé');
        loadExercices();
        return true;
      } else {
        AppHelpers.showError(result['message'] ?? 'Erreur');
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> cloturerExercice(int id) async {
    final confirm = await AppHelpers.showConfirmDialog(
      title: 'Clôturer exercice',
      content: 'Cette action est irréversible. Toutes les écritures doivent être validées.',
      confirmText: 'Clôturer',
    );
    if (confirm != true) return false;

    isSubmitting.value = true;
    try {
      final result = await _exerciceService.cloturerExercice(id);
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Exercice clôturé');
        loadExercices();
        loadCurrentExercice();
        return true;
      } else {
        AppHelpers.showError(result['message'] ?? 'Erreur');
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  void selectExercice(ExerciceModel exercice) {
    _storage.saveExerciceId(exercice.id);
    currentExercice.value = exercice;
  }
}
