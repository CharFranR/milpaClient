import 'dart:convert';

import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/match_models.dart';
import 'package:flutter_application_1/features/buyer/supply_request_models.dart';
import 'package:flutter_application_1/features/buyer/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeTokenStore extends TokenStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<void> save({required String token, required String userId}) async {
    values['token'] = token;
    values['userId'] = userId;
  }

  @override
  Future<String?> readToken() async => values['token'];

  @override
  Future<String?> readUserId() async => values['userId'];

  @override
  Future<void> clear() async {
    values.clear();
  }
}

TransactionRepository buildRepository(
  MockClient mockClient,
  FakeTokenStore store,
) => TransactionRepository(
  apiClient: ApiClient(httpClient: mockClient),
  tokenStore: store,
);

FakeTokenStore storeWithToken() =>
    FakeTokenStore()..values['token'] = 'token-123';

Map<String, dynamic> envelope(Object? data) => <String, dynamic>{'data': data};

http.Response jsonResponse(Object? data, [int statusCode = 200]) =>
    http.Response(
      jsonEncode(envelope(data)),
      statusCode,
      headers: <String, String>{
        'content-type': 'application/json; charset=utf-8',
      },
    );

Map<String, dynamic> transactionJson({
  String id = 'tx-1',
  String matchId = 'match-1',
  int status = 0,
  Object? buyerStart = '2026-10-05T10:00:00Z',
  Object? supplierStart,
  Object? buyerDelivery,
  Object? supplierDelivery,
  Object? cancelledBy,
  String cancelReason = '',
  int historyEntries = 1,
}) => <String, dynamic>{
  'id': id,
  'match_id': matchId,
  'status': status,
  'buyer_start_confirmed_at': buyerStart,
  'supplier_start_confirmed_at': supplierStart,
  'buyer_delivery_confirmed_at': buyerDelivery,
  'supplier_delivery_confirmed_at': supplierDelivery,
  'cancelled_by': cancelledBy,
  'cancel_reason': cancelReason,
  'created_at': '2026-10-04T07:42:02Z',
  'updated_at': '2026-10-05T10:00:00Z',
  'history': List<Map<String, dynamic>>.generate(
    historyEntries,
    (int index) => <String, dynamic>{
      'status': index,
      'at': '2026-10-04T07:42:02Z',
    },
  ),
};

Map<String, dynamic> reviewJson({
  String id = 'review-1',
  int rating = 5,
  String comment = 'Muy buena',
  String transactionId = 'tx-1',
  String targetId = 'supplier-1',
}) => <String, dynamic>{
  'id': id,
  'user_id': 'user-1',
  'company_id': '00000000-0000-0000-0000-000000000000',
  'rating': rating,
  'comment': comment,
  'created_at': '2026-10-06T10:00:00Z',
  'target_type': 'user',
  'target_id': targetId,
  'transaction_id': transactionId,
};

void main() {
  group('TransactionRepository fetchByMatch', () {
    test('pide la transacción del match con Bearer y parsea el DTO', () async {
      Uri? requestedUri;
      String? authorization;
      final MockClient mockClient = MockClient((http.Request request) async {
        requestedUri = request.url;
        authorization = request.headers['Authorization'];
        return jsonResponse(transactionJson());
      });

      final Transaction transaction = await buildRepository(
        mockClient,
        storeWithToken(),
      ).fetchByMatch('match-1');

      expect(requestedUri!.path, '/api/v1/transactions/matches/match-1');
      expect(authorization, 'Bearer token-123');
      expect(transaction.id, 'tx-1');
      expect(transaction.matchId, 'match-1');
      expect(transaction.status, TransactionStatus.matched);
      expect(transaction.buyerStartConfirmedAt, '2026-10-05T10:00:00Z');
      expect(transaction.supplierStartConfirmedAt, isNull);
      expect(transaction.buyerDeliveryConfirmedAt, isNull);
      expect(transaction.supplierDeliveryConfirmedAt, isNull);
      expect(transaction.cancelledBy, isNull);
      expect(transaction.cancelReason, '');
      expect(transaction.createdAt, '2026-10-04T07:42:02Z');
      expect(transaction.updatedAt, '2026-10-05T10:00:00Z');
      expect(transaction.historyCount, 1);
    });

    test('parsea una transacción cancelada con motivo y autor', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => jsonResponse(
          transactionJson(
            status: 3,
            cancelledBy: 'buyer-1',
            cancelReason: 'Sin stock',
          ),
        ),
      );

      final Transaction transaction = await buildRepository(
        mockClient,
        storeWithToken(),
      ).fetchByMatch('match-1');

      expect(transaction.status, TransactionStatus.cancelled);
      expect(transaction.cancelledBy, 'buyer-1');
      expect(transaction.cancelReason, 'Sin stock');
    });

    test('sin token responde 401 y no toca el server', () async {
      var called = false;
      final MockClient mockClient = MockClient((http.Request request) async {
        called = true;
        return jsonResponse(transactionJson());
      });

      await expectLater(
        buildRepository(mockClient, FakeTokenStore()).fetchByMatch('match-1'),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.statusCode,
            'status',
            401,
          ),
        ),
      );
      expect(called, isFalse);
    });
  });

  group('TransactionRepository fetchByRequest', () {
    test('pide la colección del request y parsea la lista', () async {
      Uri? requestedUri;
      String? authorization;
      final MockClient mockClient = MockClient((http.Request request) async {
        requestedUri = request.url;
        authorization = request.headers['Authorization'];
        return jsonResponse(<Map<String, dynamic>>[
          transactionJson(),
          transactionJson(id: 'tx-2', status: 1),
        ]);
      });

      final List<Transaction> transactions = await buildRepository(
        mockClient,
        storeWithToken(),
      ).fetchByRequest('request-1');

      expect(requestedUri!.path, '/api/v1/transactions/requests/request-1');
      expect(authorization, 'Bearer token-123');
      expect(transactions, hasLength(2));
      expect(transactions.first.id, 'tx-1');
      expect(transactions.last.status, TransactionStatus.inProgress);
    });

    test('un payload sin data devuelve lista vacía', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response(
          '{}',
          200,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        ),
      );

      expect(
        await buildRepository(mockClient, storeWithToken()).fetchByRequest(
          'request-1',
        ),
        isEmpty,
      );
    });
  });

  group('TransactionRepository confirmaciones', () {
    test('confirmStart hace POST sin cuerpo al path del server', () async {
      Uri? requestedUri;
      String? method;
      String? body;
      String? authorization;
      final MockClient mockClient = MockClient((http.Request request) async {
        requestedUri = request.url;
        method = request.method;
        body = request.body;
        authorization = request.headers['Authorization'];
        return jsonResponse(null);
      });

      await buildRepository(
        mockClient,
        storeWithToken(),
      ).confirmStart('tx-1');

      expect(requestedUri!.path, '/api/v1/transactions/tx-1/confirm-start');
      expect(method, 'POST');
      expect(body, isEmpty);
      expect(authorization, 'Bearer token-123');
    });

    test('confirmDelivery hace POST sin cuerpo al path del server', () async {
      Uri? requestedUri;
      String? method;
      final MockClient mockClient = MockClient((http.Request request) async {
        requestedUri = request.url;
        method = request.method;
        return jsonResponse(null);
      });

      await buildRepository(
        mockClient,
        storeWithToken(),
      ).confirmDelivery('tx-1');

      expect(requestedUri!.path, '/api/v1/transactions/tx-1/confirm-delivery');
      expect(method, 'POST');
    });

    test('confirmStart sin token responde 401 y no toca el server', () async {
      var called = false;
      final MockClient mockClient = MockClient((http.Request request) async {
        called = true;
        return jsonResponse(null);
      });

      await expectLater(
        buildRepository(mockClient, FakeTokenStore()).confirmStart('tx-1'),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.statusCode,
            'status',
            401,
          ),
        ),
      );
      expect(called, isFalse);
    });

    test('propaga el mensaje del server en un 409', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response(
          jsonEncode(<String, dynamic>{'error': 'already confirmed'}),
          409,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        ),
      );

      await expectLater(
        buildRepository(mockClient, storeWithToken()).confirmDelivery('tx-1'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.statusCode, 'status', 409)
              .having(
                (ApiException e) => e.message,
                'message',
                'already confirmed',
              ),
        ),
      );
    });
  });

  group('TransactionRepository cancel', () {
    test('envía el motivo en el cuerpo del POST', () async {
      Uri? requestedUri;
      String? method;
      Map<String, dynamic>? sentBody;
      final MockClient mockClient = MockClient((http.Request request) async {
        requestedUri = request.url;
        method = request.method;
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return jsonResponse(null);
      });

      await buildRepository(
        mockClient,
        storeWithToken(),
      ).cancel('tx-1', 'Sin stock');

      expect(requestedUri!.path, '/api/v1/transactions/tx-1/cancel');
      expect(method, 'POST');
      expect(sentBody, <String, dynamic>{'reason': 'Sin stock'});
    });

    test('sin token responde 401 y no toca el server', () async {
      var called = false;
      final MockClient mockClient = MockClient((http.Request request) async {
        called = true;
        return jsonResponse(null);
      });

      await expectLater(
        buildRepository(mockClient, FakeTokenStore()).cancel('tx-1', 'Sin stock'),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.statusCode,
            'status',
            401,
          ),
        ),
      );
      expect(called, isFalse);
    });
  });

  group('TransactionRepository rate', () {
    test('publica la calificación con el target del agricultor', () async {
      Uri? requestedUri;
      String? method;
      Map<String, dynamic>? sentBody;
      final MockClient mockClient = MockClient((http.Request request) async {
        requestedUri = request.url;
        method = request.method;
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return jsonResponse(reviewJson(), 201);
      });

      await buildRepository(mockClient, storeWithToken()).rate(
        transactionId: 'tx-1',
        targetId: 'supplier-1',
        rating: 5,
        comment: 'Muy buena',
      );

      expect(requestedUri!.path, '/api/v1/reviews/');
      expect(method, 'POST');
      expect(sentBody, <String, dynamic>{
        'rating': 5,
        'comment': 'Muy buena',
        'transaction_id': 'tx-1',
        'target_type': 'user',
        'target_id': 'supplier-1',
      });
    });

    test('trata un 500 como rechazo de dominio y expone el mensaje', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response(
          jsonEncode(<String, dynamic>{
            'error': 'la transacción todavía no está completada',
          }),
          500,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        ),
      );

      await expectLater(
        buildRepository(mockClient, storeWithToken()).rate(
          transactionId: 'tx-1',
          targetId: 'supplier-1',
          rating: 5,
          comment: 'Muy buena',
        ),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.statusCode, 'status', 500)
              .having(
                (ApiException e) => e.message,
                'message',
                'la transacción todavía no está completada',
              ),
        ),
      );
    });
  });

  group('TransactionRepository fetchAuthoredReviewTransactionIds', () {
    test('lee las reseñas del usuario y arma el set de transacciones', () async {
      Uri? requestedUri;
      String? authorization;
      final MockClient mockClient = MockClient((http.Request request) async {
        requestedUri = request.url;
        authorization = request.headers['Authorization'];
        return jsonResponse(<Map<String, dynamic>>[
          reviewJson(transactionId: 'tx-1'),
          reviewJson(id: 'review-2', transactionId: 'tx-2'),
        ]);
      });

      final Set<String> ids = await buildRepository(
        mockClient,
        storeWithToken(),
      ).fetchAuthoredReviewTransactionIds('user-1');

      expect(requestedUri!.path, '/api/v1/reviews/');
      expect(requestedUri!.queryParameters['user_id'], 'user-1');
      expect(authorization, 'Bearer token-123');
      expect(ids, <String>{'tx-1', 'tx-2'});
    });

    test('descarta las reseñas sin transaction_id', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => jsonResponse(<Map<String, dynamic>>[
          reviewJson(transactionId: ''),
          reviewJson(transactionId: 'tx-9'),
        ]),
      );

      expect(
        await buildRepository(
          mockClient,
          storeWithToken(),
        ).fetchAuthoredReviewTransactionIds('user-1'),
        <String>{'tx-9'},
      );
    });

    test('sin token responde 401 y no toca el server', () async {
      var called = false;
      final MockClient mockClient = MockClient((http.Request request) async {
        called = true;
        return jsonResponse(<dynamic>[]);
      });

      await expectLater(
        buildRepository(
          mockClient,
          FakeTokenStore(),
        ).fetchAuthoredReviewTransactionIds('user-1'),
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.statusCode,
            'status',
            401,
          ),
        ),
      );
      expect(called, isFalse);
    });
  });

  group('TransactionStatus y MatchStatus', () {
    test('mapea cada estado de transacción y cae a Desconocida', () {
      expect(TransactionStatus.fromWire(0), TransactionStatus.matched);
      expect(TransactionStatus.fromWire(1), TransactionStatus.inProgress);
      expect(TransactionStatus.fromWire(2), TransactionStatus.completed);
      expect(TransactionStatus.fromWire(3), TransactionStatus.cancelled);
      expect(TransactionStatus.fromWire(9), TransactionStatus.unknown);
      expect(TransactionStatus.matched.label, 'Acordada');
      expect(TransactionStatus.inProgress.label, 'En proceso');
      expect(TransactionStatus.completed.label, 'Completada');
      expect(TransactionStatus.cancelled.label, 'Cancelada');
      expect(TransactionStatus.unknown.label, 'Desconocida');
    });

    test('mapea cada estado de match y cae a Desconocido', () {
      expect(MatchStatus.fromWire(0), MatchStatus.active);
      expect(MatchStatus.fromWire(1), MatchStatus.cancelled);
      expect(MatchStatus.fromWire(9), MatchStatus.unknown);
      expect(MatchStatus.active.label, 'Activo');
      expect(MatchStatus.cancelled.label, 'Cancelado');
      expect(MatchStatus.unknown.label, 'Desconocido');
    });

    test('parsea un Match con sus montos y unidad', () {
      final Match match = Match.fromJson(<String, dynamic>{
        'id': 'match-1',
        'supply_offer': 'offer-1',
        'supply_request': 'request-1',
        'status': 0,
        'matched_amount': 500,
        'amount_unit': 1,
        'created_at': '2026-10-04T07:42:02Z',
        'updated_at': '2026-10-04T07:42:02Z',
      });

      expect(match.id, 'match-1');
      expect(match.supplyOffer, 'offer-1');
      expect(match.supplyRequest, 'request-1');
      expect(match.status, MatchStatus.active);
      expect(match.matchedAmount, 500);
      expect(match.amountUnit, MeasureUnit.pound);
      expect(match.createdAt, '2026-10-04T07:42:02Z');
    });

    test('un Match o Transaction sin campos no rompen el parseo', () {
      final Match match = Match.fromJson(<String, dynamic>{});
      expect(match.id, '');
      expect(match.supplyOffer, '');
      expect(match.status, MatchStatus.unknown);
      expect(match.matchedAmount, 0);
      expect(match.amountUnit, MeasureUnit.unknown);

      final Transaction transaction = Transaction.fromJson(<String, dynamic>{});
      expect(transaction.id, '');
      expect(transaction.matchId, '');
      expect(transaction.status, TransactionStatus.unknown);
      expect(transaction.buyerStartConfirmedAt, isNull);
      expect(transaction.cancelReason, '');
      expect(transaction.historyCount, 0);
    });
  });
}
