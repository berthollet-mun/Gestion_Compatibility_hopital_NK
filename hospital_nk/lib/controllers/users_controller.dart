import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/services/user_service.dart';
import '../core/services/role_service.dart';
import '../core/services/service_hopital_service.dart';
import '../core/utils/helpers.dart';
import '../data/models/user_model.dart';
import '../data/models/role_model.dart';
import '../data/models/service_model.dart';

class UsersController extends GetxController {
  final UserService _userService = Get.find<UserService>();
  final RoleService _roleService = Get.find<RoleService>();
  final ServiceHopitalService _serviceService = Get.find<ServiceHopitalService>();

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<UserModel> users = RxList<UserModel>();
  final RxList<RoleModel> roles = RxList<RoleModel>();
  final RxList<ServiceModel> services = RxList<ServiceModel>();
  final Rx<UserModel?> selectedUser = Rx<UserModel?>(null);

  // Filters
  final RxString searchQuery = ''.obs;
  final RxString selectedStatut = ''.obs;
  final RxInt selectedRoleId = 0.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
    loadRoles();
    loadServices();
  }

  Future<void> loadUsers({bool reset = false}) async {
    if (reset) {
      currentPage.value = 1;
      users.clear();
    }
    isLoading.value = true;
    try {
      final result = await _userService.getUsers(
        page: currentPage.value,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        statut: selectedStatut.value.isEmpty ? null : selectedStatut.value,
        roleId: selectedRoleId.value == 0 ? null : selectedRoleId.value,
      );
      if (result['success'] == true) {
        final data = result['data'];
        final items = (data['items'] as List)
            .map((u) => UserModel.fromJson(u))
            .toList();
        users.assignAll(items);
        final pagination = data['pagination'];
        totalPages.value = pagination['last_page'] ?? 1;
        totalItems.value = pagination['total'] ?? 0;
      } else {
        AppHelpers.showError(result['message'] ?? 'Erreur chargement');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadRoles() async {
    final result = await _roleService.getRoles();
    if (result['success'] == true) {
      roles.assignAll(
        (result['data'] as List).map((r) => RoleModel.fromJson(r)).toList(),
      );
    }
  }

  Future<void> loadServices() async {
    final result = await _serviceService.getServices();
    if (result['success'] == true) {
      services.assignAll(
        (result['data'] as List).map((s) => ServiceModel.fromJson(s)).toList(),
      );
    }
  }

  Future<void> loadUser(int id) async {
    isLoading.value = true;
    try {
      final result = await _userService.getUser(id);
      if (result['success'] == true) {
        selectedUser.value = UserModel.fromJson(result['data']);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createUser(Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      final result = await _userService.createUser(data);
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Utilisateur créé');
        loadUsers(reset: true);
        return true;
      } else {
        AppHelpers.showError(result['message'] ?? 'Erreur création');
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateUser(int id, Map<String, dynamic> data) async {
    isSubmitting.value = true;
    try {
      final result = await _userService.updateUser(id, data);
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Mis à jour');
        loadUsers(reset: true);
        return true;
      } else {
        AppHelpers.showError(result['message'] ?? 'Erreur mise à jour');
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deleteUser(int id) async {
    final confirm = await AppHelpers.showConfirmDialog(
      title: 'Supprimer utilisateur',
      content: 'Cette action est irréversible. Confirmer la suppression ?',
      confirmText: 'Supprimer',
      confirmColor: const Color(0xFFC62828),
    );
    if (confirm == true) {
      final result = await _userService.deleteUser(id);
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Supprimé');
        loadUsers(reset: true);
      } else {
        AppHelpers.showError(result['message'] ?? 'Erreur suppression');
      }
    }
  }

  Future<bool> resetPassword(int id, String newPassword) async {
    final result = await _userService.resetPassword(id, newPassword);
    if (result['success'] == true) {
      AppHelpers.showSuccess('Mot de passe réinitialisé');
      return true;
    } else {
      AppHelpers.showError(result['message'] ?? 'Erreur');
      return false;
    }
  }

  void search(String query) {
    searchQuery.value = query;
    loadUsers(reset: true);
  }

  void filterByStatut(String? statut) {
    selectedStatut.value = statut ?? '';
    loadUsers(reset: true);
  }

  void filterByRole(int? roleId) {
    selectedRoleId.value = roleId ?? 0;
    loadUsers(reset: true);
  }

  void nextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      loadUsers();
    }
  }

  void prevPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      loadUsers();
    }
  }
}