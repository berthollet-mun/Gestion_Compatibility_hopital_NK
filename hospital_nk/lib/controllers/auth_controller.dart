import 'package:get/get.dart';
import 'package:hospital_comptabilite/data/models/role_model.dart';
import '../core/services/auth_service.dart';
import '../core/services/storage_service.dart';
import '../core/utils/helpers.dart';
import '../data/models/user_model.dart';
import '../app/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final StorageService _storage = Get.find<StorageService>();

  final RxBool isLoading = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadUserFromStorage();
  }

  void _loadUserFromStorage() {
    if (_storage.isLoggedIn) {
      // Create a basic UserModel from storage
      currentUser.value = UserModel(
        id: _storage.userId ?? 0,
        matricule: '',
        nom: _storage.userName?.split(' ').last ?? '',
        prenom: _storage.userName?.split(' ').first ?? '',
        email: _storage.userEmail ?? '',
        statut: 'ACTIF',
        role: RoleModel(
          id: 0,
          nom: _storage.userRole ?? '',
          slug: _storage.userRoleSlug ?? '',
        ),
      );
    }
  }

  bool get isLoggedIn => _storage.isLoggedIn;

  String get userRoleSlug => _storage.userRoleSlug ?? '';
  String get userName => _storage.userName ?? '';
  String get userEmail => _storage.userEmail ?? '';
  String get userRole => _storage.userRole ?? '';

  // ─── PERMISSIONS ──────────────────────────────────────────────
  bool get isAdmin => userRoleSlug == 'admin';
  bool get isDirecteur => userRoleSlug == 'directeur-financier' || userRoleSlug == 'directeur';
  bool get isChefComptable => userRoleSlug == 'chef-comptable' || userRoleSlug == 'comptable-chef';
  bool get isAuditeur => userRoleSlug == 'auditeur-interne';
  bool get isComptable => userRoleSlug == 'comptable';
  bool get isCaissier => userRoleSlug == 'caissier';
  bool get isGestionnaireStock => userRoleSlug == 'gestionnaire-stock';

  bool get canManageUsers => isAdmin;
  bool get canViewUsers => isAdmin || isDirecteur;
  bool get canManagePlanComptable => isAdmin || isChefComptable;
  bool get canSaisirEcritures => isAdmin || isChefComptable || isComptable;
  bool get canValiderEcritures => isAdmin || isChefComptable;
  bool get canManageCaisse => isAdmin || isCaissier;
  bool get canViewCaisse => isAdmin || isCaissier || isChefComptable || isAuditeur || isComptable;
  bool get canManageBudget => isAdmin || isDirecteur || isChefComptable;
  bool get canApprouverBudget => isAdmin || isDirecteur;
  bool get canViewBulletinsPaie => isAdmin || isChefComptable || isDirecteur || isAuditeur;
  bool get canManageStock => isAdmin || isGestionnaireStock;
  bool get canViewStock => isAdmin || isGestionnaireStock || isChefComptable || isAuditeur;
  bool get canViewRapports => isAdmin || isDirecteur || isChefComptable || isAuditeur;
  bool get canViewFullRapports => isAdmin || isDirecteur || isChefComptable || isAuditeur;
  bool get canViewLogsAudit => isAdmin || isAuditeur;
  bool get canManageExercices => isAdmin;
  bool get canManageJournaux => isAdmin || isChefComptable;
  bool get canViewFactures => isAdmin || isChefComptable || isComptable || isAuditeur;
  bool get canCreateFactures => isAdmin || isChefComptable || isComptable;

  // ─── LOGIN ────────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    if (isLoading.value) return; // Guard contre les double-taps
    isLoading.value = true;
    try {
      final result = await _authService.login(email: email, password: password);
      if (result['success'] == true) {
        // 1. Recharger le user depuis le storage immédiatement
        _loadUserFromStorage();
        
        // 2. S'assurer que le token est bien présent avant de continuer
        final token = await _storage.getAccessToken();
        if (token == null || token.isEmpty) {
          throw Exception('Token manquant après login réussi');
        }

        // 3. Navigation immédiate
        Get.offAllNamed(AppRoutes.dashboard);
        
        // 4. Chargement du profil complet en arrière-plan
        // On attend un court délai pour laisser le temps à la navigation de se faire
        Future.delayed(const Duration(milliseconds: 500), () {
          _loadCurrentUserBackground();
        });
      } else {
        AppHelpers.showError(result['message'] ?? 'Identifiants incorrects');
      }
    } catch (e) {
      AppHelpers.showError('Erreur de connexion. Vérifiez votre réseau.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Charge le profil complet depuis /auth/me en arrière-plan
  Future<void> _loadCurrentUserBackground() async {
    try {
      await _loadCurrentUser();
    } catch (_) {
      // Silencieux — les infos essentielles sont déjà en storage
    }
  }

  Future<void> _loadCurrentUser() async {
    final result = await _authService.getMe();
    if (result['success'] == true) {
      final userData = result['data'];
      currentUser.value = UserModel.fromJson(userData);
      await _storage.saveUserInfo(
        userId: currentUser.value!.id,
        role: currentUser.value!.role.nom,
        roleSlug: currentUser.value!.role.slug,
        name: currentUser.value!.fullName,
        email: currentUser.value!.email,
      );
    }
  }

  // ─── LOGOUT ───────────────────────────────────────────────────
  Future<void> logout() async {
    final confirm = await AppHelpers.showConfirmDialog(
      title: 'Déconnexion',
      content: 'Voulez-vous vraiment vous déconnecter ?',
      confirmText: 'Déconnecter',
    );

    if (confirm == true) {
      isLoading.value = true;
      await _authService.logout();
      currentUser.value = null;
      isLoading.value = false;
      Get.offAllNamed(AppRoutes.login);
    }
  }

  // ─── CHANGE PASSWORD ───────────────────────────────────────────
  Future<void> changePassword(String current, String newPwd, String confirm) async {
    isLoading.value = true;
    try {
      final result = await _authService.changePassword(
        currentPassword: current,
        newPassword: newPwd,
        confirmation: confirm,
      );
      if (result['success'] == true) {
        AppHelpers.showSuccess(result['message'] ?? 'Mot de passe modifié');
      } else {
        AppHelpers.showError(result['message'] ?? 'Erreur');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // ─── REFRESH USER ─────────────────────────────────────────────
  Future<void> refreshUser() async {
    await _loadCurrentUser();
  }
}