import 'package:get/get.dart';
import 'api_service.dart';

class StockService {
  final ApiService _api = Get.find<ApiService>();

  Future<Map<String, dynamic>> getProduits({
    int page = 1,
    String? search,
    String? statut,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (statut != null && statut.isNotEmpty) params['statut'] = statut;
      final response = await _api.get('/stock/produits', queryParameters: params);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> createProduit(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/stock/produits', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> updateProduit(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/stock/produits/$id', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> enregistrerMouvement(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/stock/mouvements', data: data);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> getMouvements({
    int page = 1,
    int? produitId,
    String? type,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (produitId != null) params['produit_id'] = produitId;
      if (type != null) params['type'] = type;
      final response = await _api.get('/stock/mouvements', queryParameters: params);
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  Future<Map<String, dynamic>> getAlertes() async {
    try {
      final response = await _api.get('/stock/produits/alertes');
      return response.data;
    } catch (e) {
      return {'success': false, 'message': _err(e)};
    }
  }

  String _err(dynamic e) =>
      e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Erreur serveur';
}
