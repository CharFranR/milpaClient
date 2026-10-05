import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/match_models.dart';

class TransactionRepository {
  TransactionRepository({
    required ApiClient apiClient,
    required this._tokenStore,
  }) : _api = apiClient;

  final ApiClient _api;
  final TokenStore _tokenStore;

  Future<Transaction> fetchByMatch(String matchId) async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.get(
      '/transactions/matches/$matchId',
      token: token,
    );
    return Transaction.fromJson(json as Map<String, dynamic>);
  }

  Future<List<Transaction>> fetchByRequest(String requestId) async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.get(
      '/transactions/requests/$requestId',
      token: token,
    );
    return _listItems(json)
        .map((Map<String, dynamic> item) => Transaction.fromJson(item))
        .toList();
  }

  Future<void> confirmStart(String transactionId) async {
    final String token = await _readTokenOrThrow();
    await _api.post('/transactions/$transactionId/confirm-start', token: token);
  }

  Future<void> confirmDelivery(String transactionId) async {
    final String token = await _readTokenOrThrow();
    await _api.post(
      '/transactions/$transactionId/confirm-delivery',
      token: token,
    );
  }

  Future<void> cancel(String transactionId, String reason) async {
    final String token = await _readTokenOrThrow();
    await _api.post(
      '/transactions/$transactionId/cancel',
      body: <String, dynamic>{'reason': reason},
      token: token,
    );
  }

  Future<void> rate({
    required String transactionId,
    required String targetId,
    required int rating,
    required String comment,
  }) async {
    final String token = await _readTokenOrThrow();
    await _api.post(
      '/reviews/',
      body: <String, dynamic>{
        'rating': rating,
        'comment': comment,
        'transaction_id': transactionId,
        'target_type': 'user',
        'target_id': targetId,
      },
      token: token,
    );
  }

  Future<Set<String>> fetchAuthoredReviewTransactionIds(String userId) async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.get(
      '/reviews/',
      query: <String, String>{'user_id': userId},
      token: token,
    );
    return _listItems(json)
        .map((Map<String, dynamic> item) => item['transaction_id'] as String?)
        .whereType<String>()
        .where((String id) => id.isNotEmpty)
        .toSet();
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
