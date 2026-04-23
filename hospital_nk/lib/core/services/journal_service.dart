import 'package:get/get.dart';
import 'api_service.dart';

class JournalService {
  final ApiService _api = Get.find<ApiService>();

  Future<Map<String, dynamic>> getJournaux() async {
    try {
      final response = await _api.get('/journaux');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> createJournal(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/journaux', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> getJournalEcritures(
    int journalId, {
    int? exerciceId,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (exerciceId != null) params['exercice_id'] = exerciceId;
      final response = await _api.get('/journaux/$journalId/ecritures', queryParameters: params);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  String _err(dynamic e) =>
      e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Erreur serveur';
}
