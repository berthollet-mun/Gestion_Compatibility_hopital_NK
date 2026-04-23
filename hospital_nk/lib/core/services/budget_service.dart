import 'package:get/get.dart';
import 'api_service.dart';

class BudgetService {
  final ApiService _api = Get.find<ApiService>();

  Future<Map<String, dynamic>> getBudgets({
    int page = 1,
    int? exerciceId,
    int? serviceId,
    String? statut,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (exerciceId != null) params['exercice_id'] = exerciceId;
      if (serviceId != null) params['service_id'] = serviceId;
      if (statut != null && statut.isNotEmpty) params['statut'] = statut;

      final response = await _api.get('/budgets', queryParameters: params);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> getBudget(int id) async {
    try {
      final response = await _api.get('/budgets/$id');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> createBudget(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/budgets', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> soumettrebudget(int id) async {
    try {
      final response = await _api.put('/budgets/$id/soumettre');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> approuverBudget(int id, {String? commentaire}) async {
    try {
      final response = await _api.put('/budgets/$id/approuver', data: {
        if (commentaire != null) 'commentaire': commentaire,
      });
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> getExecution({
    int? exerciceId,
    int? serviceId,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (exerciceId != null) params['exercice_id'] = exerciceId;
      if (serviceId != null) params['service_id'] = serviceId;
      final response = await _api.get('/budgets/execution', queryParameters: params);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  String _err(dynamic e) =>
      e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Erreur serveur';
}
