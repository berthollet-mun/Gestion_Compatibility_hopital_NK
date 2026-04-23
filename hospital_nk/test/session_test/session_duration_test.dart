import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hospital_comptabilite/core/services/api_service.dart';
import 'package:hospital_comptabilite/core/services/storage_service.dart';
import 'package:hospital_comptabilite/controllers/auth_controller.dart';
import 'package:hospital_comptabilite/core/services/auth_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';

// Générer les mocks avec: flutter pub run build_runner build
@GenerateMocks([StorageService, ApiService, AuthService])
void main() {
  group('Tests de Durée de Session', () {
    late AuthController authController;
    late StorageService mockStorage;
    late AuthService mockAuthService;

    setUp(() {
      mockStorage = MockStorageService();
      mockAuthService = MockAuthService();
      
      Get.put<StorageService>(mockStorage);
      Get.put<AuthService>(mockAuthService);
      
      authController = AuthController();
      Get.put(authController);
    });

    tearDown(() {
      Get.reset();
    });

    test('La session doit rester active au-delà de 10 secondes après le login', () async {
      // 1. Simuler un login réussi
      when(mockAuthService.login(email: anyNamed('email'), password: anyNamed('password')))
          .thenAnswer((_) async => {
                'success': true,
                'data': {
                  'token': 'fake_token',
                  'refresh_token': 'fake_refresh',
                  'user': {'id': 1, 'nom': 'Test', 'prenom': 'User', 'email': 'test@test.com'}
                }
              });

      when(mockStorage.isLoggedIn).thenReturn(true);
      when(mockStorage.userId).thenReturn(1);
      when(mockStorage.userRoleSlug).thenReturn('admin');

      // 2. Exécuter le login
      await authController.login('test@test.com', 'password123');

      // 3. Vérifier qu'on est connecté
      expect(authController.isLoggedIn, true);

      // 4. Attendre 12 secondes (plus que le délai problématique de 10s)
      print('Attente de 12 secondes pour vérifier la stabilité de la session...');
      await Future.delayed(const Duration(seconds: 12));

      // 5. Vérifier que la session est TOUJOURS active
      expect(authController.isLoggedIn, true, reason: 'La session a expiré prématurément avant 10s');
      
      // 6. Simuler une requête API après ce délai
      when(mockAuthService.getMe()).thenAnswer((_) async => {
        'success': true, 
        'data': {'id': 1, 'email': 'test@test.com'}
      });
      
      await authController.refreshUser();
      expect(authController.isLoggedIn, true);
      print('✅ Succès: La session est restée active après 12 secondes.');
    });
  });
}
