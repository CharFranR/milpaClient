import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/match_models.dart';

class MatchRepository {
  MatchRepository({
    required ApiClient apiClient,
    required this._tokenStore,
  }) : _api = apiClient;

  final ApiClient _api;
  final TokenStore _tokenStore;

  Future<List<PrioritizedOffer>> fetchPrioritized(String requestId) async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.get(
      '/matches/requests/$requestId/prioritized',
      token: token,
    );
    return _listItems(json)
        .map((Map<String, dynamic> item) => PrioritizedOffer.fromJson(item))
        .toList();
  }

  Future<MatchResult> like(String offerId) async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.post('/matches/like/$offerId', token: token);
    return MatchResult.fromJson(json as Map<String, dynamic>);
  }

  Future<void> pass(String offerId) async {
    final String token = await _readTokenOrThrow();
    await _api.post('/matches/pass/$offerId', token: token);
  }

  Future<List<Match>> fetchMatches(String requestId) async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.get(
      '/matches/requests/$requestId',
      token: token,
    );
    return _listItems(json)
        .map((Map<String, dynamic> item) => Match.fromJson(item))
        .toList();
  }

  Future<Match> fetchMatch(String matchId) async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.get('/matches/$matchId', token: token);
    return Match.fromJson(json as Map<String, dynamic>);
  }

  Future<MatchOffer> fetchSupplyOffer(String offerId) async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.get(
      '/supply-offers/$offerId',
      token: token,
    );
    return MatchOffer.fromJson(json as Map<String, dynamic>);
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
