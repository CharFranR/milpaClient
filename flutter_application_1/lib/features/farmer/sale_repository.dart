import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/conversation_models.dart';
import 'package:flutter_application_1/features/buyer/match_models.dart'
    hide OfferStatus;
import 'package:flutter_application_1/features/buyer/offering_models.dart';
import 'package:flutter_application_1/features/buyer/supply_request_models.dart';
import 'package:flutter_application_1/features/farmer/order_models.dart';
import 'package:flutter_application_1/features/farmer/sale_models.dart';

class SaleRepository {
  SaleRepository({
    required ApiClient apiClient,
    required this._tokenStore,
  }) : _api = apiClient;

  final ApiClient _api;
  final TokenStore _tokenStore;

  Future<List<Sale>> fetchMySales() async {
    final String token = await _readTokenOrThrow();
    final dynamic offersJson = await _api.get('/supply-offers/', token: token);
    final List<MyOffer> offers = _listItems(offersJson)
        .map(MyOffer.fromJson)
        .where((MyOffer offer) => offer.status == OfferStatus.matched)
        .toList();
    final List<Sale> sales = <Sale>[];
    for (final MyOffer offer in offers) {
      final Sale? sale = await _saleFor(offer, token);
      if (sale != null) sales.add(sale);
    }
    return sales;
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

  Future<Map<String, Conversation>> fetchConversationsByMatch() async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.get('/conversations', token: token);
    final Map<String, Conversation> byMatch = <String, Conversation>{};
    for (final Conversation conversation
        in _listItems(json).map(Conversation.fromJson)) {
      final String? matchId = conversation.matchId;
      if (matchId != null && matchId.isNotEmpty) {
        byMatch.putIfAbsent(matchId, () => conversation);
      }
    }
    return byMatch;
  }

  Future<Sale?> _saleFor(MyOffer offer, String token) async {
    final Transaction? transaction = await _findTransaction(offer, token);
    if (transaction == null) return null;
    final SupplyRequest request = await _fetchRequest(
      offer.supplyRequestId,
      token,
    );
    final String buyerName = await _fetchBuyerName(request.buyerId, token);
    return Sale(
      offerId: offer.id,
      requestId: request.id,
      productName: request.productName,
      amountUnit: request.amountUnit,
      quantity: offer.totalAmount,
      pricePerUnit: offer.pricePerUnit,
      municipality: request.municipality,
      buyerName: buyerName,
      transaction: transaction,
    );
  }

  Future<Transaction?> _findTransaction(MyOffer offer, String token) async {
    final List<Transaction> transactions;
    try {
      final dynamic json = await _api.get(
        '/transactions/requests/${offer.supplyRequestId}',
        token: token,
      );
      transactions = _listItems(json).map(Transaction.fromJson).toList();
    } on ApiException catch (error) {
      if (error.statusCode == 403 || error.statusCode == 404) return null;
      rethrow;
    }
    if (transactions.isEmpty) return null;
    if (transactions.length == 1) return transactions.single;
    for (final Transaction transaction in transactions) {
      final Match match = await _fetchMatch(transaction.matchId, token);
      if (match.supplyOffer == offer.id) return transaction;
    }
    return null;
  }

  Future<Match> _fetchMatch(String matchId, String token) async {
    final dynamic json = await _api.get('/matches/$matchId', token: token);
    return Match.fromJson(json as Map<String, dynamic>);
  }

  Future<SupplyRequest> _fetchRequest(String id, String token) async {
    final dynamic json = await _api.get('/supply-requests/$id', token: token);
    return SupplyRequest.fromJson(json as Map<String, dynamic>);
  }

  Future<String> _fetchBuyerName(String buyerId, String token) async {
    if (buyerId.isEmpty) return '';
    try {
      final dynamic json = await _api.get('/users/$buyerId', token: token);
      return SellerProfile.fromJson(json as Map<String, dynamic>).fullName;
    } catch (_) {
      return '';
    }
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
