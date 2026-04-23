import 'package:get/get.dart';
import 'api_service.dart';

class FactureService {
  final ApiService _api = Get.find<ApiService>();

  Future<Map<String, dynamic>> getFactures({
    int page = 1,
    String? type,
    String? statut,
    String? search,
    int? exerciceId,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (type != null) params['type'] = type;
      if (statut != null && statut.isNotEmpty) params['statut'] = statut;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (exerciceId != null) params['exercice_id'] = exerciceId;

      final response = await _api.get('/factures', queryParameters: params);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> getFacture(int id) async {
    try {
      final response = await _api.get('/factures/$id');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> createFacture(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/factures', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> enregistrerPaiement(int factureId, Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/factures/$factureId/paiement', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  String _err(dynamic e) =>
      e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Erreur serveur';
}
