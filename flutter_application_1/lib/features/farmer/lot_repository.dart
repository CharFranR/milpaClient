import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/liquidation_models.dart';
import 'package:flutter_application_1/features/farmer/lot_models.dart';

class LotRepository {
  LotRepository({required ApiClient apiClient, required this._tokenStore})
    : _api = apiClient;

  final ApiClient _api;
  final TokenStore _tokenStore;

  Future<List<Liquidation>> fetchMine(String supplierId) async {
    final dynamic json = await _api.get(
      '/liquidations/',
      query: <String, String>{'supplier_id': supplierId},
    );
    return _listItems(json)
        .map((Map<String, dynamic> item) => Liquidation.fromJson(item))
        .toList();
  }

  Future<Liquidation> fetchById(String id) async {
    final dynamic json = await _api.get('/liquidations/$id');
    return Liquidation.fromJson(json as Map<String, dynamic>);
  }

  Future<Liquidation> publish(LotDraft draft) async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.post(
      '/liquidations/',
      body: draft.toJson(),
      token: token,
    );
    return Liquidation.fromJson(json as Map<String, dynamic>);
  }

  Future<List<InterestedBuyer>> fetchInterests(String lotId) async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.get(
      '/liquidations/$lotId/interests',
      token: token,
    );
    return _listItems(json).map(InterestedBuyer.fromJson).toList();
  }

  Future<void> assign(String lotId, {String? buyerId}) async {
    final String token = await _readTokenOrThrow();
    await _api.post(
      '/liquidations/$lotId/assign',
      body: buyerId == null ? null : <String, dynamic>{'buyer_id': buyerId},
      token: token,
    );
  }

  Future<void> updateVisibility(
    String lotId,
    LiquidationVisibility visibility,
  ) async {
    final String token = await _readTokenOrThrow();
    await _api.patch(
      '/liquidations/$lotId',
      body: <String, dynamic>{'visibility': visibility.wire},
      token: token,
    );
  }

  Future<void> remove(String lotId) async {
    final String token = await _readTokenOrThrow();
    await _api.delete('/liquidations/$lotId', token: token);
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
