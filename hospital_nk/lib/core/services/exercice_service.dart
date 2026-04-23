import 'package:get/get.dart';
import 'api_service.dart';

class ExerciceService {
  final ApiService _api = Get.find<ApiService>();

  Future<Map<String, dynamic>> getExercices() async {
    try {
      final response = await _api.get('/exercices');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> getCurrentExercice() async {
    try {
      final response = await _api.get('/exercices/current');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> createExercice(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/exercices', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> cloturerExercice(int id, {String? commentaire}) async {
    try {
      final response = await _api.put('/exercices/$id/cloturer', data: {
        if (commentaire != null) 'commentaire': commentaire,
      });
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  String _err(dynamic e) =>
      e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Erreur serveur';
}
