import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/farmer/order_models.dart';

class OrderRepository {
  OrderRepository({
    required ApiClient apiClient,
    required this._tokenStore,
  }) : _api = apiClient;

  final ApiClient _api;
  final TokenStore _tokenStore;

  Future<List<AvailableRequest>> fetchAvailable() async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.get(
      '/supply-requests/available',
      token: token,
    );
    return _listItems(json).map(AvailableRequest.fromJson).toList();
  }

  Future<MyOffer> offerOn(OfferDraft draft) async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.post(
      '/supply-offers/',
      body: draft.toJson(),
      token: token,
    );
    return MyOffer.fromJson(
      json is Map<String, dynamic> ? json : <String, dynamic>{},
    );
  }

  Future<List<MyOffer>> fetchMyOffers() async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.get('/supply-offers/', token: token);
    return _listItems(json).map(MyOffer.fromJson).toList();
  }

  Future<void> updateOffer(String id, OfferDraft draft) async {
    final String token = await _readTokenOrThrow();
    await _api.patch(
      '/supply-offers/$id',
      body: draft.toUpdateJson(),
      token: token,
    );
  }

  Future<void> withdrawOffer(String id) async {
    final String token = await _readTokenOrThrow();
    await _api.post('/supply-offers/$id/withdraw', token: token);
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
