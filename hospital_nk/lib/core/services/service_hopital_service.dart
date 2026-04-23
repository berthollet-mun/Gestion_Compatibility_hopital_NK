import 'package:get/get.dart';
import 'api_service.dart';

class ServiceHopitalService {
  final ApiService _api = Get.find<ApiService>();

  Future<Map<String, dynamic>> getServices() async {
    try {
      final response = await _api.get('/services');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> getService(int id) async {
    try {
      final response = await _api.get('/services/$id');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> createService(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/services', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> updateService(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/services/$id', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> getServiceBudget(int serviceId, {int? exerciceId}) async {
    try {
      final params = <String, dynamic>{};
      if (exerciceId != null) params['exercice_id'] = exerciceId;
      final response = await _api.get('/services/$serviceId/budget', queryParameters: params);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  String _err(dynamic e) =>
      e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Erreur serveur';
}
