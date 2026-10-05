import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/liquidation_models.dart';

class LiquidationRepository {
  LiquidationRepository({
    required ApiClient apiClient,
    required this._tokenStore,
  }) : _api = apiClient;

  final ApiClient _api;
  final TokenStore _tokenStore;

  Future<List<Liquidation>> fetchOpen() async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.get('/liquidations/open', token: token);
    return _listItems(json)
        .map((Map<String, dynamic> item) => Liquidation.fromJson(item))
        .toList();
  }

  Future<Liquidation> fetchById(String id) async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.get('/liquidations/$id', token: token);
    return Liquidation.fromJson(json as Map<String, dynamic>);
  }

  Future<void> expressInterest(String id) async {
    final String token = await _readTokenOrThrow();
    await _api.post('/liquidations/$id/interest', token: token);
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
