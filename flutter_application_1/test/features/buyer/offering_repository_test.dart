import 'dart:convert';

import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_config.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/features/buyer/offering_models.dart';
import 'package:flutter_application_1/features/buyer/offering_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

OfferingRepository buildRepository(MockClient mockClient) =>
    OfferingRepository(apiClient: ApiClient(httpClient: mockClient));

Map<String, dynamic> envelope(Map<String, dynamic> data) => <String, dynamic>{
  'data': data,
};

void main() {
  group('OfferingRepository fetchDetail', () {
    test('parsea todos los campos del detalle', () async {
      Uri? requestedUri;
      final MockClient mockClient = MockClient((http.Request request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode(
            envelope(<String, dynamic>{
              'id': 'offering-1',
              'user_id': 'farmer-1',
              'type': 0,
              'name': 'Tomate cherry',
              'description': 'Cosecha de la semana',
              'price': 25.5,
              'image_url': 'https://cdn.milpa.com/fotos/tomate.jpg',
              'created_at': '2026-01-01T00:00:00Z',
              'updated_at': '2026-01-02T00:00:00Z',
              'extra': 'ignorado',
            }),
          ),
          200,
        );
      });

      final OfferingDetail detail = await buildRepository(mockClient)
          .fetchDetail('offering-1');

      expect(requestedUri!.path, '/api/v1/offerings/offering-1');
      expect(detail.id, 'offering-1');
      expect(detail.userId, 'farmer-1');
      expect(detail.type, 0);
      expect(detail.name, 'Tomate cherry');
      expect(detail.description, 'Cosecha de la semana');
      expect(detail.price, 25.5);
      expect(detail.imageUrl, 'https://cdn.milpa.com/fotos/tomate.jpg');
      expect(detail.imageSrc, 'https://cdn.milpa.com/fotos/tomate.jpg');
    });

    test('convierte el type numérico a entero', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response(
          jsonEncode(
            envelope(<String, dynamic>{'id': 'offering-2', 'type': 1.0}),
          ),
          200,
        ),
      );

      final OfferingDetail detail = await buildRepository(mockClient)
          .fetchDetail('offering-2');

      expect(detail.type, 1);
    });

    test('resuelve la ruta relativa de la imagen', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response(
          jsonEncode(
            envelope(<String, dynamic>{
              'id': 'offering-3',
              'image_url': 'uploads/tomate.jpg',
            }),
          ),
          200,
        ),
      );

      final OfferingDetail detail = await buildRepository(mockClient)
          .fetchDetail('offering-3');

      expect(detail.imageSrc, '${ApiConfig.apiBaseUrl}/images/tomate.jpg');
    });

    test('usa valores por defecto cuando faltan campos', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response(
          jsonEncode(envelope(<String, dynamic>{'id': 'offering-4'})),
          200,
        ),
      );

      final OfferingDetail detail = await buildRepository(mockClient)
          .fetchDetail('offering-4');

      expect(detail.userId, '');
      expect(detail.type, 0);
      expect(detail.name, '');
      expect(detail.description, '');
      expect(detail.price, 0);
      expect(detail.imageUrl, '');
      expect(detail.imageSrc, isNull);
    });

    test('no adjunta Authorization en endpoints públicos', () async {
      bool hasAuthorization = true;
      final MockClient mockClient = MockClient((http.Request request) async {
        hasAuthorization = request.headers.containsKey('Authorization');
        return http.Response(
          jsonEncode(envelope(<String, dynamic>{'id': 'offering-5'})),
          200,
        );
      });

      await buildRepository(mockClient).fetchDetail('offering-5');

      expect(hasAuthorization, isFalse);
    });

    test('mapea un error del servidor a ApiException', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response.bytes(
          utf8.encode('{"error":"oferta no encontrada"}'),
          404,
        ),
      );

      await expectLater(
        buildRepository(mockClient).fetchDetail('missing'),
        throwsA(
          isA<ApiException>()
              .having(
                (ApiException error) => error.statusCode,
                'statusCode',
                404,
              )
              .having(
                (ApiException error) => error.message,
                'message',
                'oferta no encontrada',
              ),
        ),
      );
    });
  });

  group('OfferingRepository fetchSeller', () {
    test('parsea el perfil público del agricultor', () async {
      Uri? requestedUri;
      final MockClient mockClient = MockClient((http.Request request) async {
        requestedUri = request.url;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(
              envelope(<String, dynamic>{
                'id': 'farmer-1',
                'first_name': 'María',
                'last_name': 'López',
                'role': 1,
                'department': 'Matagalpa',
                'municipality': 'Sebaco',
                'created_at': '2026-01-01T00:00:00Z',
                'updated_at': '2026-01-02T00:00:00Z',
              }),
            ),
          ),
          200,
        );
      });

      final SellerProfile seller = await buildRepository(mockClient)
          .fetchSeller('farmer-1');

      expect(requestedUri!.path, '/api/v1/users/farmer-1');
      expect(seller.id, 'farmer-1');
      expect(seller.firstName, 'María');
      expect(seller.lastName, 'López');
      expect(seller.role, 1);
      expect(seller.department, 'Matagalpa');
      expect(seller.municipality, 'Sebaco');
      expect(seller.fullName, 'María López');
    });

    test('usa valores por defecto cuando faltan campos', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response(
          jsonEncode(envelope(<String, dynamic>{'id': 'farmer-2'})),
          200,
        ),
      );

      final SellerProfile seller = await buildRepository(mockClient)
          .fetchSeller('farmer-2');

      expect(seller.firstName, '');
      expect(seller.lastName, '');
      expect(seller.role, 0);
      expect(seller.department, '');
      expect(seller.municipality, '');
      expect(seller.fullName, '');
    });
  });

  group('OfferingRepository fetchRating', () {
    test('envía la consulta exacta y parsea el resumen', () async {
      Uri? requestedUri;
      final MockClient mockClient = MockClient((http.Request request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode(
            envelope(<String, dynamic>{
              'target_type': 'user',
              'target_id': 'farmer-1',
              'average': 4.5,
              'count': 12,
            }),
          ),
          200,
        );
      });

      final RatingSummary rating = await buildRepository(mockClient)
          .fetchRating('farmer-1');

      expect(requestedUri!.path, '/api/v1/reviews/average');
      expect(requestedUri!.queryParameters, <String, String>{
        'target_type': 'user',
        'target_id': 'farmer-1',
      });
      expect(rating.average, 4.5);
      expect(rating.count, 12);
      expect(rating.hasReviews, isTrue);
    });

    test('hasReviews es false cuando no hay reseñas', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response(
          jsonEncode(envelope(<String, dynamic>{'average': 0, 'count': 0})),
          200,
        ),
      );

      final RatingSummary rating = await buildRepository(mockClient)
          .fetchRating('farmer-3');

      expect(rating.average, 0);
      expect(rating.count, 0);
      expect(rating.hasReviews, isFalse);
    });

    test('usa valores por defecto cuando faltan campos', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async =>
            http.Response(jsonEncode(envelope(<String, dynamic>{})), 200),
      );

      final RatingSummary rating = await buildRepository(mockClient)
          .fetchRating('farmer-4');

      expect(rating.average, 0);
      expect(rating.count, 0);
      expect(rating.hasReviews, isFalse);
    });
  });
}
