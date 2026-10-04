import 'dart:convert';

import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/supply_request_models.dart';
import 'package:flutter_application_1/features/buyer/supply_request_repository.dart';
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

SupplyRequestRepository buildRepository(
  MockClient mockClient,
  FakeTokenStore store,
) => SupplyRequestRepository(
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

Map<String, dynamic> requestJson({
  String id = 'request-1',
  int status = 0,
  int amountUnit = 0,
  int unitOfMeasure = 2,
}) => <String, dynamic>{
  'id': id,
  'buyer_id': 'buyer-1',
  'product_name': 'Café pergamino',
  'total_amount': 800,
  'actual_amount': 800,
  'amount_unit': amountUnit,
  'number_of_units': 100,
  'amount_per_unit': 8,
  'unit_of_measure': unitOfMeasure,
  'address': <String, dynamic>{
    'ID': 'address-1',
    'Department': 'Managua',
    'Municipality': 'Managua',
    'AddressLine': 'Bodega 12, mercado Mayoreo',
    'Latitude': 12.136,
    'Longitude': -86.251,
  },
  'request_deadline': '2026-11-01T00:00:00Z',
  'delivery_deadline': '2026-12-01T00:00:00Z',
  'description': 'Compra de temporada',
  'multiple_providers': true,
  'min_amount_per_provider': 100,
  'status': status,
  'created_at': '2026-10-04T07:42:02Z',
  'updated_at': '2026-10-04T07:42:02Z',
};

SupplyRequestDraft buildDraft() => SupplyRequestDraft(
  productName: 'Café pergamino',
  description: 'Compra de temporada',
  totalAmount: 800,
  actualAmount: 800,
  amountUnit: MeasureUnit.kilogram,
  numberOfUnits: 100,
  amountPerUnit: 8,
  unitOfMeasure: MeasureUnit.ton,
  department: 'Managua',
  municipality: 'Managua',
  addressLine: 'Bodega 12, mercado Mayoreo',
  latitude: 12.136,
  longitude: -86.251,
  requestDeadline: DateTime.utc(2026, 11, 1),
  deliveryDeadline: DateTime.utc(2026, 12, 1),
  multipleProviders: true,
  minAmountPerProvider: 100,
);

void main() {
  group('SupplyRequestRepository fetchAll', () {
    test('pide la colección con Bearer y parsea la lista', () async {
      Uri? requestedUri;
      String? authorization;
      final MockClient mockClient = MockClient((http.Request request) async {
        requestedUri = request.url;
        authorization = request.headers['Authorization'];
        return jsonResponse(<Map<String, dynamic>>[
          requestJson(),
          requestJson(id: '2'),
        ]);
      });

      final List<SupplyRequest> requests = await buildRepository(
        mockClient,
        storeWithToken(),
      ).fetchAll();

      expect(requestedUri!.path, '/api/v1/supply-requests/');
      expect(authorization, 'Bearer token-123');
      expect(requests, hasLength(2));
      expect(requests.first.id, 'request-1');
      expect(requests.first.productName, 'Café pergamino');
      expect(requests.first.totalAmount, 800);
      expect(requests.first.actualAmount, 800);
      expect(requests.first.status, SupplyRequestStatus.open);
      expect(requests.first.amountUnit, MeasureUnit.kilogram);
      expect(requests.first.unitOfMeasure, MeasureUnit.ton);
      expect(requests.first.department, 'Managua');
      expect(requests.first.addressLine, 'Bodega 12, mercado Mayoreo');
      expect(requests.first.requestDeadline, '2026-11-01T00:00:00Z');
      expect(requests.first.multipleProviders, isTrue);
      expect(requests.first.minAmountPerProvider, 100);
    });

    test('sin token responde 401 y no toca el server', () async {
      var called = false;
      final MockClient mockClient = MockClient((http.Request request) async {
        called = true;
        return jsonResponse(<dynamic>[]);
      });

      await expectLater(
        buildRepository(mockClient, FakeTokenStore()).fetchAll(),
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
        await buildRepository(mockClient, storeWithToken()).fetchAll(),
        isEmpty,
      );
    });
  });

  group('SupplyRequest status y unidades', () {
    test('mapea cada status del server', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => jsonResponse(<Map<String, dynamic>>[
          requestJson(id: '0', status: 0),
          requestJson(id: '1', status: 1),
          requestJson(id: '2', status: 2),
          requestJson(id: '3', status: 3),
        ]),
      );

      final List<SupplyRequest> requests = await buildRepository(
        mockClient,
        storeWithToken(),
      ).fetchAll();

      expect(
        requests.map((SupplyRequest r) => r.status),
        <SupplyRequestStatus>[
          SupplyRequestStatus.open,
          SupplyRequestStatus.cancelled,
          SupplyRequestStatus.completed,
          SupplyRequestStatus.expired,
        ],
      );
    });

    test('un status o unidad desconocidos no rompen el parseo', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => jsonResponse(<Map<String, dynamic>>[
          requestJson(status: 9, amountUnit: 7, unitOfMeasure: 8),
        ]),
      );

      final SupplyRequest request =
          (await buildRepository(mockClient, storeWithToken()).fetchAll())
              .single;

      expect(request.status, SupplyRequestStatus.unknown);
      expect(request.amountUnit, MeasureUnit.unknown);
      expect(request.unitOfMeasure, MeasureUnit.unknown);
    });

    test('etiquetas, wire values y estado accionable', () {
      expect(SupplyRequestStatus.open.label, 'Abierta');
      expect(SupplyRequestStatus.cancelled.label, 'Cancelada');
      expect(SupplyRequestStatus.completed.label, 'Completada');
      expect(SupplyRequestStatus.expired.label, 'Expirada');
      expect(SupplyRequestStatus.open.isEditable, isTrue);
      expect(SupplyRequestStatus.completed.isEditable, isFalse);
      expect(MeasureUnit.kilogram.label, 'kg');
      expect(MeasureUnit.pound.label, 'lb');
      expect(MeasureUnit.ton.label, 'ton');
      expect(MeasureUnit.kilogram.wireValue, 0);
      expect(MeasureUnit.pound.wireValue, 1);
      expect(MeasureUnit.ton.wireValue, 2);
      expect(MeasureUnit.unknown.label, '—');
    });

    test('calcula lo ya solicitado y arma la ubicación', () {
      final SupplyRequest request = SupplyRequest.fromJson(<String, dynamic>{
        'id': 'request-1',
        'status': 0,
        'total_amount': 800,
        'actual_amount': 300,
        'address': <String, dynamic>{
          'Municipality': 'Masate',
          'Department': 'Masaya',
        },
      });

      expect(request.committedAmount, 500);
      expect(request.location, 'Masate, Masaya');
      expect(request.isOpen, isTrue);
    });

    test('sin total no divide ni inventa lo solicitado', () {
      final SupplyRequest request = SupplyRequest.fromJson(
        <String, dynamic>{'id': 'request-2', 'actual_amount': 300},
      );

      expect(request.committedAmount, 0);
      expect(request.location, '');
      expect(request.isOpen, isFalse);
    });
  });

  group('SupplyRequestRepository create', () {
    test('envía POST con el body del server y parsea la respuesta', () async {
      String? method;
      Uri? requestedUri;
      Map<String, dynamic>? sentBody;
      final MockClient mockClient = MockClient((http.Request request) async {
        method = request.method;
        requestedUri = request.url;
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return jsonResponse(requestJson(), 201);
      });

      final SupplyRequest created = await buildRepository(
        mockClient,
        storeWithToken(),
      ).create(buildDraft());

      expect(method, 'POST');
      expect(requestedUri!.path, '/api/v1/supply-requests/');
      expect(sentBody, <String, dynamic>{
        'product_name': 'Café pergamino',
        'total_amount': 800.0,
        'amount_unit': 0,
        'number_of_units': 100.0,
        'amount_per_unit': 8.0,
        'unit_of_measure': 2,
        'address': <String, dynamic>{
          'Department': 'Managua',
          'Municipality': 'Managua',
          'AddressLine': 'Bodega 12, mercado Mayoreo',
          'Latitude': 12.136,
          'Longitude': -86.251,
        },
        'request_deadline': '2026-11-01T00:00:00.000Z',
        'delivery_deadline': '2026-12-01T00:00:00.000Z',
        'description': 'Compra de temporada',
        'multiple_providers': true,
        'min_amount_per_provider': 100.0,
      });
      expect(created.id, 'request-1');
    });

    test('sin token responde 401 y no toca el server', () async {
      var called = false;
      final MockClient mockClient = MockClient((http.Request request) async {
        called = true;
        return jsonResponse(requestJson(), 201);
      });

      await expectLater(
        buildRepository(mockClient, FakeTokenStore()).create(buildDraft()),
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

  group('SupplyRequestRepository update', () {
    test('envía PATCH con el estado completo, actual_amount incluido', () async {
      String? method;
      Uri? requestedUri;
      Map<String, dynamic>? sentBody;
      final MockClient mockClient = MockClient((http.Request request) async {
        method = request.method;
        requestedUri = request.url;
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return jsonResponse(<String, dynamic>{});
      });

      await buildRepository(
        mockClient,
        storeWithToken(),
      ).update('request-1', buildDraft());

      expect(method, 'PATCH');
      expect(requestedUri!.path, '/api/v1/supply-requests/request-1');
      expect(sentBody!['actual_amount'], 800.0);
      expect(sentBody!['product_name'], 'Café pergamino');
      expect(sentBody!['unit_of_measure'], 2);
      expect(sentBody!['min_amount_per_provider'], 100.0);
    });

    test('sin token responde 401 y no toca el server', () async {
      var called = false;
      final MockClient mockClient = MockClient((http.Request request) async {
        called = true;
        return jsonResponse(<String, dynamic>{});
      });

      await expectLater(
        buildRepository(
          mockClient,
          FakeTokenStore(),
        ).update('request-1', buildDraft()),
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

  group('SupplyRequestRepository cancel', () {
    test('envía POST al endpoint de cancelación con Bearer', () async {
      String? method;
      Uri? requestedUri;
      String? authorization;
      final MockClient mockClient = MockClient((http.Request request) async {
        method = request.method;
        requestedUri = request.url;
        authorization = request.headers['Authorization'];
        return jsonResponse(<String, dynamic>{});
      });

      await buildRepository(mockClient, storeWithToken()).cancel('request-1');

      expect(method, 'POST');
      expect(requestedUri!.path, '/api/v1/supply-requests/request-1/cancel');
      expect(authorization, 'Bearer token-123');
    });

    test('sin token responde 401 y no toca el server', () async {
      var called = false;
      final MockClient mockClient = MockClient((http.Request request) async {
        called = true;
        return jsonResponse(<String, dynamic>{});
      });

      await expectLater(
        buildRepository(mockClient, FakeTokenStore()).cancel('request-1'),
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

  group('SupplyRequestDraft', () {
    test('parte de una solicitud del server para el formulario de edición', () {
      final SupplyRequest request = SupplyRequest.fromJson(requestJson());
      final SupplyRequestDraft draft = SupplyRequestDraft.fromRequest(request);

      expect(draft.productName, 'Café pergamino');
      expect(draft.totalAmount, 800);
      expect(draft.actualAmount, 800);
      expect(draft.amountUnit, MeasureUnit.kilogram);
      expect(draft.unitOfMeasure, MeasureUnit.ton);
      expect(draft.department, 'Managua');
      expect(draft.municipality, 'Managua');
      expect(draft.addressLine, 'Bodega 12, mercado Mayoreo');
      expect(draft.requestDeadline, DateTime.utc(2026, 11, 1));
      expect(draft.deliveryDeadline, DateTime.utc(2026, 12, 1));
      expect(draft.multipleProviders, isTrue);
      expect(draft.minAmountPerProvider, 100);
    });

    test('la fecha cero del server y la fecha ausente se distinguen', () {
      final SupplyRequest zeroed = SupplyRequest.fromJson(<String, dynamic>{
        'id': 'request-9',
        'request_deadline': '0001-01-01T00:00:00Z',
      });
      final SupplyRequest missing = SupplyRequest.fromJson(
        <String, dynamic>{'id': 'request-10'},
      );

      expect(
        SupplyRequestDraft.fromRequest(zeroed).requestDeadline,
        DateTime.utc(1, 1, 1),
      );
      expect(
        SupplyRequestDraft.fromRequest(missing).requestDeadline,
        isNull,
      );
    });
  });
}
