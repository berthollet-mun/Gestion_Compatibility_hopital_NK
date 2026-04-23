import 'package:get/get.dart';
import 'api_service.dart';

class EcritureService {
  final ApiService _api = Get.find<ApiService>();

  Future<Map<String, dynamic>> getEcritures({
    int page = 1,
    int? exerciceId,
    int? journalId,
    String? statut,
    String? dateDebut,
    String? dateFin,
    String? search,
    int? compteId,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (exerciceId != null) params['exercice_id'] = exerciceId;
      if (journalId != null) params['journal_id'] = journalId;
      if (statut != null && statut.isNotEmpty) params['statut'] = statut;
      if (dateDebut != null) params['date_debut'] = dateDebut;
      if (dateFin != null) params['date_fin'] = dateFin;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (compteId != null) params['compte_id'] = compteId;

      final response = await _api.get('/ecritures', queryParameters: params);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> getEcriture(int id) async {
    try {
      final response = await _api.get('/ecritures/$id');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> createEcriture(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/ecritures', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> updateEcriture(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/ecritures/$id', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> soumettreEcriture(int id, {String? commentaire}) async {
    try {
      final response = await _api.put('/ecritures/$id/soumettre', data: {
        if (commentaire != null) 'commentaire': commentaire,
      });
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> validerEcriture(int id, {String? commentaire}) async {
    try {
      final response = await _api.put('/ecritures/$id/valider', data: {
        if (commentaire != null) 'commentaire': commentaire,
      });
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> rejeterEcriture(int id, {required String commentaire}) async {
    try {
      final response = await _api.put('/ecritures/$id/rejeter', data: {
        'commentaire': commentaire,
      });
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  String _err(dynamic e) =>
      e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Erreur serveur';
}
