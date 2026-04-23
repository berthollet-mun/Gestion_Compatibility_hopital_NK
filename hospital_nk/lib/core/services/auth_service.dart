import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api = Get.find<ApiService>();
  final StorageService _storage = Get.find<StorageService>();

  // ─── LOGIN ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data;

      if (data['success'] == true) {
        final authData = data['data'];
        final accessToken = authData['token'] ?? authData['access_token'];
        
        if (accessToken == null || accessToken.isEmpty) {
          throw Exception('Le serveur n\'a pas retourné de token');
        }

        // Sauvegarder les tokens en attendant l'écriture complète
        await _storage.saveTokens(
          accessToken: accessToken,
          refreshToken: authData['refresh_token'] ?? '',
        );

        // Sauvegarder les infos user de base reçues au login
        final user = authData['user'];
        if (user != null) {
          final roleObj = user['role'] as Map<String, dynamic>?;
          final roleName = roleObj?['nom'] ?? user['role_nom'] ?? '';
          final roleSlug = roleObj?['slug'] ?? user['role_slug'] ?? '';
          
          await _storage.saveUserInfo(
            userId: user['id'] ?? 0,
            role: roleName,
            roleSlug: roleSlug,
            name: '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim(),
            email: user['email'] ?? '',
          );
        }
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ─── GET ME ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _api.get('/auth/me');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ─── REFRESH TOKEN ─────────────────────────────────────────────
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        return {'success': false, 'message': 'Aucun refresh token'};
      }
      final response = await _api.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      final data = response.data;
      if (data['success'] == true) {
        final authData = data['data'];
        await _storage.saveTokens(
          accessToken: authData['token'] ?? authData['access_token'] ?? '',
          refreshToken: authData['refresh_token'] ?? refreshToken,
        );
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  // ─── LOGOUT ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // Ignore error on logout
    }
    await _storage.clearAll();
    return {'success': true, 'message': 'Déconnexion réussie'};
  }

  // ─── CHANGE PASSWORD ──────────────────────────────────────────
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    try {
      final response = await _api.post('/auth/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmation,
      });
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _handleError(e)};
    }
  }

  String _handleError(dynamic e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        return 'Le serveur met trop de temps à répondre. Réessayez.';
      }
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('message')) {
          return data['message'];
        }
      }
      return 'Erreur réseau: ${e.message}';
    }
    if (e is Exception) return e.toString().replaceAll('Exception: ', '');
    return 'Une erreur est survenue';
  }
}
