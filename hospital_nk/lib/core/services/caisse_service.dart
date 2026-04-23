import 'package:get/get.dart';
import 'api_service.dart';

class CaisseService {
  final ApiService _api = Get.find<ApiService>();

  // ─── SESSIONS ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> getSessions({
    int page = 1,
    String? statut,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (statut != null && statut.isNotEmpty) params['statut'] = statut;
      final response = await _api.get('/caisse/sessions', queryParameters: params);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> ouvrirCaisse({
    required double soldeOuverture,
    String devise = 'CDF',
    String? commentaire,
  }) async {
    try {
      final response = await _api.post('/caisse/ouvrir', data: {
        'solde_ouverture': soldeOuverture,
        'devise': devise,
        if (commentaire != null) 'commentaire': commentaire,
      });
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> fermerCaisse(
    int sessionId, {
    required double soldeReel,
    String? commentaire,
  }) async {
    try {
      final response = await _api.put('/caisse/sessions/$sessionId/fermer', data: {
        'solde_reel': soldeReel,
        if (commentaire != null) 'commentaire': commentaire,
      });
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  // ─── TRANSACTIONS ──────────────────────────────────────────────
  Future<Map<String, dynamic>> enregistrerTransaction(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/caisse/transactions', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  // ─── RAPPORT ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> getRapportSession(int sessionId) async {
    try {
      final response = await _api.get('/caisse/sessions/$sessionId/rapport');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  String _err(dynamic e) =>
      e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Erreur serveur';
}
