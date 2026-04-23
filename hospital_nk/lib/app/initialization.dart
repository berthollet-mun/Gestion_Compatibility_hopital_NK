import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/services/storage_service.dart';
import '../core/services/api_service.dart';

class AppInitialization {
  static Future<void> init() async {
    final logger = Logger();
    try {
      // 1. Init StorageService first (tokens, user info)
      await Get.putAsync(() => StorageService().init());
      logger.i('✅ StorageService initialized');

      // 2. Init ApiService (HTTP client with interceptors)
      Get.put(ApiService());
      logger.i('✅ ApiService initialized');

      // 3. Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        logger.w('⚠️ No network connection detected');
      } else {
        logger.i('✅ Network available: $connectivityResult');
      }

      // 4. Check if we have a stored token
      final storage = Get.find<StorageService>();
      if (storage.isLoggedIn) {
        logger.i('✅ User session found: ${storage.userName} (${storage.userRoleSlug})');
      } else {
        logger.i('ℹ️ No active session - user needs to login');
      }

      logger.i('🏥 App initialized successfully - Hôpital NK Comptabilité');
    } catch (e) {
      logger.e('❌ App initialization error: $e');
    }
  }
}