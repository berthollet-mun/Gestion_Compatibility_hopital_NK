import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:logger/logger.dart';
import 'storage_service.dart';

class ApiService extends GetxService {
  static const String baseUrl = 'http://192.168.1.69/hospital/api';
  static const int connectTimeout =
      30000; // 30s - Plus robuste sur réseau mobile
  static const int receiveTimeout =
      60000; // 60s - PHP peut être lent au démarrage

  late Dio _dio;
  final Logger _logger = Logger();
  
  // Pour synchroniser le rafraîchissement des tokens
  Completer<bool>? _refreshCompleter;

  ApiService() {
    _init();
  }

  void _init() {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: connectTimeout),
      receiveTimeout: const Duration(milliseconds: receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio = Dio(options);
    // Ordre des intercepteurs : 
    // onRequest: Logging -> Error -> Auth
    // onError: Auth -> Error -> Logging (Auth traite le 401 avant que Error ne le transforme)
    _dio.interceptors.add(_AuthInterceptor(this));
    _dio.interceptors.add(_ErrorInterceptor());
    _dio.interceptors.add(_LoggingInterceptor(_logger));
  }

  Dio get dio => _dio;

  // ─── Generic HTTP Methods ──────────────────────────────────────
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete(path,
        data: data, queryParameters: queryParameters, options: options);
  }
}

// ─── Auth Interceptor ──────────────────────────────────────────
class _AuthInterceptor extends Interceptor {
  final ApiService _apiService;
  final Logger _logger = Logger();
  _AuthInterceptor(this._apiService);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final storage = Get.find<StorageService>();
      final token = await storage.getAccessToken();

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        _logger.d('🔑 Token injecté dans: ${options.path}');
      } else {
        _logger.w('⚠️ Requête sans token vers: ${options.path}');
      }
    } catch (e) {
      _logger.e('❌ Erreur injection token dans Interceptor: $e');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final storage = Get.find<StorageService>();
    
    // On ne gère que les erreurs 401 (Non autorisé) pour le refresh
    if (err.response?.statusCode == 401) {
      _logger.w('⚠️ 401 Unauthorized détecté sur: ${err.requestOptions.path}');

      // Vérifier si c'est déjà une tentative de refresh pour éviter la boucle infinie
      if (err.requestOptions.path.contains('/auth/refresh')) {
        _logger.e('❌ Échec du refresh (401 sur /auth/refresh) -> Déconnexion');
        _handleLogout();
        return handler.next(err);
      }

      // Éviter de re-tenter une requête qui a déjà été re-tentée après un refresh
      if (err.requestOptions.extra['retried'] == true) {
        _logger.e('❌ La re-tentative a encore échoué avec 401 -> Déconnexion');
        _handleLogout();
        return handler.next(err);
      }

      // Token expired - try refresh (avec synchronisation)
      bool refreshed = false;
      
      if (_apiService._refreshCompleter != null) {
        _logger.i('⏳ Attente du rafraîchissement en cours lancé par une autre requête...');
        refreshed = await _apiService._refreshCompleter!.future;
      } else {
        _apiService._refreshCompleter = Completer<bool>();
        _logger.i('🔄 Tentative de rafraîchissement du token...');
        
        refreshed = await _tryRefreshToken();
        _apiService._refreshCompleter!.complete(refreshed);
        _apiService._refreshCompleter = null;
      }
      
      if (refreshed) {
        // Re-tentative de la requête originale avec le nouveau token
        try {
          final newToken = await storage.getAccessToken();
          
          // IMPORTANT: Créer une nouvelle RequestOptions pour la re-tentative
          // pour s'assurer que les changements sont pris en compte
          final requestOptions = err.requestOptions;
          requestOptions.headers['Authorization'] = 'Bearer $newToken';
          requestOptions.extra['retried'] = true; // Marquer pour éviter les boucles
          
          _logger.i('🚀 Re-tentative de [${requestOptions.method}] ${requestOptions.path} avec nouveau token');
          
          final response = await _apiService.dio.fetch(requestOptions);
          return handler.resolve(response);
        } catch (e) {
          _logger.e('❌ Échec de la re-tentative après refresh: $e');
          return handler.next(err);
        }
      } else {
        _logger.e('❌ Rafraîchissement du token échoué ou annulé -> Déconnexion forcée');
        _handleLogout();
        return handler.next(err);
      }
    }
    
    // Log des erreurs de timeout pour aider au diagnostic du problème des 10s
    if (err.type == DioExceptionType.connectionTimeout || 
        err.type == DioExceptionType.receiveTimeout) {
      _logger.e('⏲️ Timeout détecté (${ApiService.connectTimeout}ms): ${err.requestOptions.path}');
    }

    handler.next(err);
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final storage = Get.find<StorageService>();
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _logger.w('⚠️ Aucun refresh token trouvé en stockage');
        return false;
      }

      // Utiliser une instance Dio propre pour le refresh (pour éviter les intercepteurs)
      final dio = Dio(BaseOptions(
        baseUrl: ApiService.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiService.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiService.receiveTimeout),
      ));
      
      final response = await dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        // Supporter 'token' ET 'access_token'
        final newToken = data['token'] ?? data['access_token'];
        if (newToken != null && newToken.isNotEmpty) {
          await storage.saveTokens(
            accessToken: newToken,
            refreshToken: data['refresh_token'] ?? refreshToken,
          );
          return true;
        }
      }
      _logger.w('⚠️ Réponse invalide lors du refresh: ${response.data}');
    } catch (e) {
      _logger.e('❌ Exception lors du refresh token: $e');
      return false;
    }
    return false;
  }

  void _handleLogout() {
    try {
      Get.find<StorageService>().clearAll();
    } catch (_) {}
    Get.offAllNamed('/login');
  }
}

// ─── Logging Interceptor ───────────────────────────────────────
class _LoggingInterceptor extends Interceptor {
  final Logger logger;
  _LoggingInterceptor(this.logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final hasAuth = options.headers.containsKey('Authorization');
    logger.d('🌐 ${options.method} ${options.path} [Auth: $hasAuth]');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.d('✅ ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e(
        '❌ ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}');
    handler.next(err);
  }
}

// ─── Error Interceptor ─────────────────────────────────────────
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message = 'Une erreur est survenue';

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      message = 'Délai de connexion dépassé. Vérifiez votre réseau.';
    } else if (err.type == DioExceptionType.connectionError) {
      message =
          'Impossible de se connecter au serveur. Vérifiez votre connexion.';
    } else if (err.response != null) {
      final data = err.response?.data;
      if (data is Map && data.containsKey('message')) {
        message = data['message'] ?? message;
      }
    }

    err = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: message,
    );

    handler.next(err);
  }
}
