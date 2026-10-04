import 'dart:convert';

import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/match_models.dart';
import 'package:flutter_application_1/features/buyer/match_repository.dart';
import 'package:flutter_application_1/features/buyer/supply_request_models.dart';
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

MatchRepository buildRepository(
  MockClient mockClient,
  FakeTokenStore store,
) => MatchRepository(
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

Map<String, dynamic> offerJson({
  String id = 'offer-1',
  int status = 0,
  int measurement = 0,
  Object? pricePerUnit = 12.5,
}) => <String, dynamic>{
  'id': id,
  'supplier_id': 'supplier-1',
  'supply_request_id': 'request-1',
  'total_amount': 500,
  'measurement': measurement,
  'price_per_unit': pricePerUnit,
  'comments': 'Entrega temprano en la bodega',
  'delivery_day': '2026-10-20T00:00:00Z',
  'delivery_available': true,
  'status': status,
  'created_at': '2026-10-04T07:42:02Z',
  'updated_at': '2026-10-04T07:42:02Z',
};

Map<String, dynamic> contributionJson({
  String factor = 'distance',
  double weight = 0.3,
  double score = 0.66,
  double weightedScore = 0.2,
}) => <String, dynamic>{
  'factor': factor,
  'weight': weight,
  'score': score,
  'weighted_score': weightedScore,
};

Map<String, dynamic> prioritizedJson({
  String id = 'offer-1',
  double score = 0.55,
  double availableQuantity = 120,
  double? distanceKm = 12.5,
}) => <String, dynamic>{
  'offer': offerJson(id: id),
  'score': score,
  'available_quantity': availableQuantity,
  'distance_km': ?distanceKm,
  'contributions': <Map<String, dynamic>>[
    contributionJson(),
    contributionJson(
      factor: 'price',
      weight: 0.15,
      score: 1,
      weightedScore: 0.15,
    ),
  ],
};

void main() {
  group('MatchRepository fetchPrioritized', () {
    test('pide la shortlist priorizada y parsea ofertas y aportes', () async {
      Uri? requestedUri;
      String? authorization;
      final MockClient mockClient = MockClient((http.Request request) async {
        requestedUri = request.url;
        authorization = request.headers['Authorization'];
        return jsonResponse(<Map<String, dynamic>>[prioritizedJson()]);
      });

      final List<PrioritizedOffer> offers = await buildRepository(
        mockClient,
        storeWithToken(),
      ).fetchPrioritized('request-1');

      expect(
        requestedUri!.path,
        '/api/v1/matches/requests/request-1/prioritized',
      );
      expect(authorization, 'Bearer token-123');
      expect(offers, hasLength(1));

      final PrioritizedOffer prioritized = offers.single;
      expect(prioritized.score, 0.55);
      expect(prioritized.availableQuantity, 120);
      expect(prioritized.distanceKm, 12.5);
      expect(prioritized.contributions, hasLength(2));
      expect(prioritized.contributions.first.factor, 'distance');
      expect(prioritized.contributions.first.weight, 0.3);
      expect(prioritized.contributions.first.score, 0.66);
      expect(prioritized.contributions.first.weightedScore, 0.2);

      final MatchOffer offer = prioritized.offer;
      expect(offer.id, 'offer-1');
      expect(offer.supplierId, 'supplier-1');
      expect(offer.supplyRequest, 'request-1');
      expect(offer.totalAmount, 500);
      expect(offer.amountUnit, MeasureUnit.kilogram);
      expect(offer.pricePerUnit, 12.5);
      expect(offer.comments, 'Entrega temprano en la bodega');
      expect(offer.proposedDeliveryDay, '2026-10-20T00:00:00Z');
      expect(offer.deliveryAvailable, isTrue);
      expect(offer.status, OfferStatus.active);
    });

    test('tolera distance_km, offer y aportes ausentes', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => jsonResponse(<dynamic>[
          prioritizedJson(distanceKm: null),
          <String, dynamic>{'score': 0.1},
        ]),
      );

      final List<PrioritizedOffer> offers = await buildRepository(
        mockClient,
        storeWithToken(),
      ).fetchPrioritized('request-1');

      expect(offers, hasLength(2));
      expect(offers.first.distanceKm, isNull);
      expect(offers.last.offer.id, '');
      expect(offers.last.contributions, isEmpty);
    });

    test('sin token responde 401 y no toca el server', () async {
      var called = false;
      final MockClient mockClient = MockClient((http.Request request) async {
        called = true;
        return jsonResponse(<dynamic>[]);
      });

      await expectLater(
        buildRepository(mockClient, FakeTokenStore()).fetchPrioritized(
          'request-1',
        ),
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

  group('MatchRepository like', () {
    test('hace POST y lee match y transacción del sobre', () async {
      Uri? requestedUri;
      String? method;
      String? authorization;
      final MockClient mockClient = MockClient((http.Request request) async {
        requestedUri = request.url;
        method = request.method;
        authorization = request.headers['Authorization'];
        return jsonResponse(<String, dynamic>{
          'match': <String, dynamic>{'id': 'match-7', 'status': 0},
          'transaction': <String, dynamic>{'id': 'tx-9', 'match_id': 'match-7'},
        }, 201);
      });

      final MatchResult result = await buildRepository(
        mockClient,
        storeWithToken(),
      ).like('offer-1');

      expect(requestedUri!.path, '/api/v1/matches/like/offer-1');
      expect(method, 'POST');
      expect(authorization, 'Bearer token-123');
      expect(result.matchId, 'match-7');
      expect(result.transactionId, 'tx-9');
    });

    test('sin token responde 401 y no toca el server', () async {
      var called = false;
      final MockClient mockClient = MockClient((http.Request request) async {
        called = true;
        return jsonResponse(<String, dynamic>{});
      });

      await expectLater(
        buildRepository(mockClient, FakeTokenStore()).like('offer-1'),
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
          jsonEncode(<String, dynamic>{'error': 'offer not actionable'}),
          409,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        ),
      );

      await expectLater(
        buildRepository(mockClient, storeWithToken()).like('offer-1'),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.statusCode, 'status', 409)
              .having((ApiException e) => e.message, 'message', 'offer not actionable'),
        ),
      );
    });
  });

  group('MatchRepository pass', () {
    test('hace POST al path de pass', () async {
      Uri? requestedUri;
      String? method;
      String? authorization;
      final MockClient mockClient = MockClient((http.Request request) async {
        requestedUri = request.url;
        method = request.method;
        authorization = request.headers['Authorization'];
        return jsonResponse(<String, dynamic>{});
      });

      await buildRepository(mockClient, storeWithToken()).pass('offer-2');

      expect(requestedUri!.path, '/api/v1/matches/pass/offer-2');
      expect(method, 'POST');
      expect(authorization, 'Bearer token-123');
    });

    test('sin token responde 401 y no toca el server', () async {
      var called = false;
      final MockClient mockClient = MockClient((http.Request request) async {
        called = true;
        return jsonResponse(<String, dynamic>{});
      });

      await expectLater(
        buildRepository(mockClient, FakeTokenStore()).pass('offer-2'),
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

  group('OfferStatus', () {
    test('mapea cada estado y cae a Desconocida', () {
      expect(OfferStatus.fromWire(0), OfferStatus.active);
      expect(OfferStatus.fromWire(1), OfferStatus.matched);
      expect(OfferStatus.fromWire(2), OfferStatus.rejected);
      expect(OfferStatus.fromWire(3), OfferStatus.withdrawn);
      expect(OfferStatus.fromWire(9), OfferStatus.unknown);
      expect(OfferStatus.active.label, 'Activa');
      expect(OfferStatus.matched.label, 'Aceptada');
      expect(OfferStatus.rejected.label, 'Rechazada');
      expect(OfferStatus.withdrawn.label, 'Retirada');
      expect(OfferStatus.unknown.label, 'Desconocida');
    });

    test('etiqueta en español los factores del desglose', () {
      expect(
        ScoreContribution.fromJson(contributionJson()).label,
        'Distancia',
      );
      expect(
        ScoreContribution.fromJson(contributionJson(factor: 'availability')).label,
        'Disponibilidad',
      );
      expect(
        ScoreContribution.fromJson(contributionJson(factor: 'price')).label,
        'Precio',
      );
      expect(
        ScoreContribution.fromJson(contributionJson(factor: 'delivery_time')).label,
        'Tiempo de entrega',
      );
      expect(
        ScoreContribution.fromJson(contributionJson(factor: 'reputation')).label,
        'Reputación',
      );
    });
  });
}
