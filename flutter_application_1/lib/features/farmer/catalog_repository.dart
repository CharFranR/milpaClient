import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/farmer/product_models.dart';

class CatalogRepository {
  CatalogRepository({required ApiClient apiClient, required this._tokenStore})
    : _api = apiClient;

  final ApiClient _api;
  final TokenStore _tokenStore;

  Future<List<FarmerProduct>> fetchMine(String userId) async {
    final dynamic json = await _api.get(
      '/offerings/',
      query: <String, String>{'user_id': userId},
    );
    return _listItems(json)
        .map((Map<String, dynamic> item) => FarmerProduct.fromJson(item))
        .toList();
  }

  Future<List<FarmerCategory>> fetchCategories() async {
    final dynamic json = await _api.get('/categories');
    return (json as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(FarmerCategory.fromJson)
        .toList();
  }

  Future<FarmerProduct> publish(ProductDraft draft) async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.post(
      '/offerings/',
      body: draft.toJson(),
      token: token,
    );
    return FarmerProduct.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deactivate(String id) async {
    final String token = await _readTokenOrThrow();
    await _api.patch('/offerings/$id/status', token: token);
  }

  Future<void> renew(String id, DateTime expiresAt) async {
    final String token = await _readTokenOrThrow();
    await _api.patch(
      '/offerings/$id/renew',
      body: <String, dynamic>{
        'expires_at': expiresAt.toUtc().toIso8601String(),
      },
      token: token,
    );
  }

  Future<String> uploadImage({
    required String filePath,
    required String filename,
  }) async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.postMultipart(
      '/images/',
      field: 'image',
      filePath: filePath,
      filename: filename,
      token: token,
    );
    final String path = json is Map<String, dynamic>
        ? (json['path'] as String? ?? '')
        : '';
    if (path.isEmpty) {
      throw const ApiException(
        500,
        'No pudimos subir la foto. Probá de nuevo.',
      );
    }
    return path;
  }

  Future<String> _readTokenOrThrow() async {
    final String? token = await _tokenStore.readToken();
    if (token == null) {
      throw const ApiException(401, 'Sesión no disponible');
    }
    return token;
  }

  List<Map<String, dynamic>> _listItems(dynamic json) => json is List
      ? json.whereType<Map<String, dynamic>>().toList()
      : <Map<String, dynamic>>[];
}
