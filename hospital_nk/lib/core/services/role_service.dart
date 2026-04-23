import 'package:get/get.dart';
import 'api_service.dart';

class RoleService {
  final ApiService _api = Get.find<ApiService>();

  Future<Map<String, dynamic>> getRoles() async {
    try {
      final response = await _api.get('/roles');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> getPermissions() async {
    try {
      final response = await _api.get('/roles/permissions');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> createRole(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/roles', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> updateRole(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/roles/$id', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  String _err(dynamic e) =>
      e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Erreur serveur';
}
