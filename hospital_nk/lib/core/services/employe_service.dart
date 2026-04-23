import 'package:get/get.dart';
import 'api_service.dart';

class EmployeService {
  final ApiService _api = Get.find<ApiService>();

  Future<Map<String, dynamic>> getEmployes({
    int page = 1,
    String? search,
    int? serviceId,
    String? statut,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (serviceId != null) params['service_id'] = serviceId;
      if (statut != null && statut.isNotEmpty) params['statut'] = statut;

      final response = await _api.get('/employes', queryParameters: params);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> getEmploye(int id) async {
    try {
      final response = await _api.get('/employes/$id');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> createEmploye(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/employes', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> updateEmploye(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/employes/$id', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  // ─── SALAIRES / BULLETINS ──────────────────────────────────────
  Future<Map<String, dynamic>> getBulletins({
    int page = 1,
    int? mois,
    int? annee,
    int? employeId,
    String? statut,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (mois != null) params['mois'] = mois;
      if (annee != null) params['annee'] = annee;
      if (employeId != null) params['employe_id'] = employeId;
      if (statut != null && statut.isNotEmpty) params['statut'] = statut;

      final response = await _api.get('/salaires/bulletins', queryParameters: params);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> createBulletin(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/salaires/bulletins', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> validerBulletin(int id) async {
    try {
      final response = await _api.put('/salaires/bulletins/$id/valider');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  String _err(dynamic e) =>
      e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Erreur serveur';
}
