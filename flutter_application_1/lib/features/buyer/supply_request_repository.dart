import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/supply_request_models.dart';

class SupplyRequestRepository {
  SupplyRequestRepository({
    required ApiClient apiClient,
    required this._tokenStore,
  }) : _api = apiClient;

  final ApiClient _api;
  final TokenStore _tokenStore;

  Future<List<SupplyRequest>> fetchAll() async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.get('/supply-requests/', token: token);
    return _listItems(json)
        .map((Map<String, dynamic> item) => SupplyRequest.fromJson(item))
        .toList();
  }

  Future<SupplyRequest> create(SupplyRequestDraft draft) async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.post(
      '/supply-requests/',
      body: draft.toCreateJson(),
      token: token,
    );
    return SupplyRequest.fromJson(json as Map<String, dynamic>);
  }

  Future<void> update(String id, SupplyRequestDraft draft) async {
    final String token = await _readTokenOrThrow();
    await _api.patch(
      '/supply-requests/$id',
      body: draft.toUpdateJson(),
      token: token,
    );
  }

  Future<void> cancel(String id) async {
    final String token = await _readTokenOrThrow();
    await _api.post('/supply-requests/$id/cancel', token: token);
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
