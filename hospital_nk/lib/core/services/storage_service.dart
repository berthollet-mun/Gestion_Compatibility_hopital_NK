import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends GetxService {
  late FlutterSecureStorage _secureStorage;
  late SharedPreferences _prefs;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';
  static const String _userRoleSlugKey = 'user_role_slug';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _exerciceIdKey = 'exercice_id';
  static const String _themeKey = 'theme_mode';

  Future<StorageService> init() async {
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  // ─── SECURE TOKEN STORAGE ──────────────────────────────────────
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    print('💾 StorageService: Sauvegarde des tokens (Access: ${accessToken.substring(0, 10)}...)');
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    // Vérification immédiate pour forcer le flush système si nécessaire
    final saved = await _secureStorage.read(key: _accessTokenKey);
    if (saved == accessToken) {
      print('✅ StorageService: Token vérifié avec succès après écriture');
    } else {
      print('⚠️ StorageService: Échec de vérification du token après écriture !');
    }
  }

  Future<String?> getAccessToken() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    if (token != null && token.isNotEmpty) {
      // print('🔑 StorageService: Token lu (${token.substring(0, 10)}...)');
    } else {
      print('❌ StorageService: Aucun token trouvé en stockage');
    }
    return token;
  }

  Future<String?> getRefreshToken() async =>
      _secureStorage.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  // ─── USER INFO (SharedPreferences) ────────────────────────────
  Future<void> saveUserInfo({
    required int userId,
    required String role,
    required String roleSlug,
    required String name,
    required String email,
  }) async {
    await _prefs.setInt(_userIdKey, userId);
    await _prefs.setString(_userRoleKey, role);
    await _prefs.setString(_userRoleSlugKey, roleSlug);
    await _prefs.setString(_userNameKey, name);
    await _prefs.setString(_userEmailKey, email);
  }

  int? get userId => _prefs.getInt(_userIdKey);
  String? get userRole => _prefs.getString(_userRoleKey);
  String? get userRoleSlug => _prefs.getString(_userRoleSlugKey);
  String? get userName => _prefs.getString(_userNameKey);
  String? get userEmail => _prefs.getString(_userEmailKey);

  // ─── EXERCICE ─────────────────────────────────────────────────
  Future<void> saveExerciceId(int id) async =>
      _prefs.setInt(_exerciceIdKey, id);
  int get exerciceId => _prefs.getInt(_exerciceIdKey) ?? 1;

  // ─── THEME ────────────────────────────────────────────────────
  Future<void> saveTheme(String mode) async =>
      _prefs.setString(_themeKey, mode);
  String get themeMode => _prefs.getString(_themeKey) ?? 'light';

  // ─── CLEAR ALL ────────────────────────────────────────────────
  Future<void> clearAll() async {
    await clearTokens();
    await _prefs.clear();
  }

  bool get isLoggedIn => userId != null && userRoleSlug != null;
}