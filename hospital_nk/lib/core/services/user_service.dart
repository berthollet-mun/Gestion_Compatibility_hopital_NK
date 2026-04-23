import 'package:get/get.dart';
import 'api_service.dart';

class UserService {
  final ApiService _api = Get.find<ApiService>();

  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int perPage = 20,
    String? search,
    String? statut,
    int? roleId,
    int? serviceId,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (statut != null && statut.isNotEmpty) params['statut'] = statut;
      if (roleId != null && roleId > 0) params['role_id'] = roleId;
      if (serviceId != null && serviceId > 0) params['service_id'] = serviceId;

      final response = await _api.get('/users', queryParameters: params);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> getUser(int id) async {
    try {
      final response = await _api.get('/users/$id');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/users', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/users/$id', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> deleteUser(int id) async {
    try {
      final response = await _api.delete('/users/$id');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> resetPassword(int id, String newPassword) async {
    try {
      final response = await _api.post('/users/$id/reset-password', data: {
        'new_password': newPassword,
      });
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  String _err(dynamic e) =>
      e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Erreur serveur';
}
