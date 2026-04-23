import 'package:get/get.dart';
import 'api_service.dart';

class PlanComptableService {
  final ApiService _api = Get.find<ApiService>();

  Future<Map<String, dynamic>> getComptes({
    int page = 1,
    int perPage = 50,
    int? classe,
    String? type,
    String? search,
    bool? actif,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (classe != null) params['classe'] = classe;
      if (type != null) params['type'] = type;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (actif != null) params['actif'] = actif ? 1 : 0;

      final response = await _api.get('/plan-comptable', queryParameters: params);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> getArborescence() async {
    try {
      final response = await _api.get('/plan-comptable/arborescence');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> createCompte(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/plan-comptable', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> updateCompte(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/plan-comptable/$id', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  String _err(dynamic e) =>
      e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Erreur serveur';
}
