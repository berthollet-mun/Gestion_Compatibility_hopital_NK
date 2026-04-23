import 'package:get/get.dart';
import 'api_service.dart';

class RapportService {
  final ApiService _api = Get.find<ApiService>();

  Future<Map<String, dynamic>> getDashboard({int? exerciceId}) async {
    try {
      final params = <String, dynamic>{};
      if (exerciceId != null) params['exercice_id'] = exerciceId;
      final response = await _api.get('/rapports/dashboard', queryParameters: params);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> getGrandLivre({
    required int compteId,
    required String dateDebut,
    required String dateFin,
    int? exerciceId,
  }) async {
    try {
      final params = <String, dynamic>{
        'compte_id': compteId,
        'date_debut': dateDebut,
        'date_fin': dateFin,
      };
      if (exerciceId != null) params['exercice_id'] = exerciceId;
      final response = await _api.get('/rapports/grand-livre', queryParameters: params);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> getBalance({int? exerciceId}) async {
    try {
      final params = <String, dynamic>{};
      if (exerciceId != null) params['exercice_id'] = exerciceId;
      final response = await _api.get('/rapports/balance', queryParameters: params);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  // ─── TRESORERIE ────────────────────────────────────────────────
  Future<Map<String, dynamic>> enregistrerMouvementTresorerie(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/tresorerie/mouvements', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> effectuerRapprochement(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/tresorerie/rapprochement', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  String _err(dynamic e) =>
      e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Erreur serveur';
}
