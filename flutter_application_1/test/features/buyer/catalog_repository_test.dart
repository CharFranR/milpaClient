import 'dart:convert';

import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_config.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/features/buyer/catalog_models.dart';
import 'package:flutter_application_1/features/buyer/catalog_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

CatalogRepository buildRepository(MockClient mockClient) =>
    CatalogRepository(apiClient: ApiClient(httpClient: mockClient));

Map<String, dynamic> pageEnvelope({
  List<Map<String, dynamic>> results = const <Map<String, dynamic>>[],
  int totalHits = 0,
  int page = 1,
  int pageSize = 20,
  int totalPages = 0,
}) => <String, dynamic>{
  'data': <String, dynamic>{
    'results': results,
    'total_hits': totalHits,
    'page': page,
    'page_size': pageSize,
    'total_pages': totalPages,
  },
};

void main() {
  group('CatalogRepository search', () {
    test('parsea resultados, totales y hasMore', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response(
          jsonEncode(
            pageEnvelope(
              results: <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'product-1',
                  'name': 'Tomate cherry',
                  'description': 'Cosecha de la semana',
                  'price': 25.5,
                  'type': 'vegetable',
                  'image_url': 'uploads/tomate.jpg',
                  'farmer_id': 'farmer-1',
                  'farmer_name': 'Finca El Roble',
                  'farmer_verified': true,
                  'department': 'Managua',
                  'municipality': 'Tipitapa',
                  'latitude': 12.5,
                  'longitude': -86.25,
                },
              ],
              totalHits: 30,
              page: 1,
              pageSize: 20,
              totalPages: 2,
            ),
          ),
          200,
        ),
      );

      final CatalogPage response = await buildRepository(mockClient).search();

      expect(response.results, hasLength(1));
      final CatalogItem item = response.results.single;
      expect(item.id, 'product-1');
      expect(item.name, 'Tomate cherry');
      expect(item.description, 'Cosecha de la semana');
      expect(item.price, 25.5);
      expect(item.type, 'vegetable');
      expect(item.imageUrl, 'uploads/tomate.jpg');
      expect(item.farmerId, 'farmer-1');
      expect(item.farmerName, 'Finca El Roble');
      expect(item.farmerVerified, isTrue);
      expect(item.department, 'Managua');
      expect(item.municipality, 'Tipitapa');
      expect(item.latitude, 12.5);
      expect(item.longitude, -86.25);
      expect(response.totalHits, 30);
      expect(response.page, 1);
      expect(response.pageSize, 20);
      expect(response.totalPages, 2);
      expect(response.hasMore, isTrue);
    });

    test('deja hasMore en false en la última página', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response(
          jsonEncode(pageEnvelope(totalHits: 3, page: 2, totalPages: 2)),
          200,
        ),
      );

      final CatalogPage response = await buildRepository(mockClient)
          .search(page: 2);

      expect(response.hasMore, isFalse);
    });

    test('envía la ruta y los parámetros esperados', () async {
      Uri? requestedUri;
      final MockClient mockClient = MockClient((http.Request request) async {
        requestedUri = request.url;
        return http.Response(jsonEncode(pageEnvelope(pageSize: 5)), 200);
      });

      await buildRepository(mockClient).search(
        term: 'tomate',
        categoryId: 'cat-1',
        sort: CatalogSort.priceDesc,
        page: 2,
        pageSize: 5,
      );

      expect(requestedUri!.path, '/api/v1/search');
      expect(requestedUri!.queryParameters, <String, String>{
        'term': 'tomate',
        'category_id': 'cat-1',
        'sort': 'price_desc',
        'page': '2',
        'page_size': '5',
      });
    });

    test('omite term y category_id cuando vienen vacíos', () async {
      Uri? requestedUri;
      final MockClient mockClient = MockClient((http.Request request) async {
        requestedUri = request.url;
        return http.Response(jsonEncode(pageEnvelope()), 200);
      });

      await buildRepository(mockClient)
          .search(term: '', categoryId: '', sort: CatalogSort.priceAsc);

      expect(requestedUri!.queryParameters, <String, String>{
        'sort': 'price_asc',
        'page': '1',
        'page_size': '20',
      });
    });

    test('no adjunta Authorization en endpoints públicos', () async {
      bool hasAuthorization = true;
      final MockClient mockClient = MockClient((http.Request request) async {
        hasAuthorization = request.headers.containsKey('Authorization');
        return http.Response(jsonEncode(pageEnvelope()), 200);
      });

      await buildRepository(mockClient).search();

      expect(hasAuthorization, isFalse);
    });

    test('mapea un error del servidor a ApiException con su mensaje', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response.bytes(
          utf8.encode('{"error":"término de búsqueda inválido"}'),
          400,
        ),
      );

      await expectLater(
        buildRepository(mockClient).search(term: 'x'),
        throwsA(
          isA<ApiException>()
              .having(
                (ApiException error) => error.statusCode,
                'statusCode',
                400,
              )
              .having(
                (ApiException error) => error.message,
                'message',
                'término de búsqueda inválido',
              ),
        ),
      );
    });
  });

  group('CatalogRepository fetchCategories', () {
    test('parsea la lista de categorías', () async {
      Uri? requestedUri;
      final MockClient mockClient = MockClient((http.Request request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode(<String, dynamic>{
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'cat-1',
                'name': 'Verduras',
                'description': 'Productos frescos',
              },
              <String, dynamic>{
                'id': 'cat-2',
                'name': 'Frutas',
                'description': '',
              },
            ],
          }),
          200,
        );
      });

      final List<CatalogCategory> categories = await buildRepository(mockClient)
          .fetchCategories();

      expect(requestedUri!.path, '/api/v1/categories');
      expect(categories, hasLength(2));
      expect(categories.first.id, 'cat-1');
      expect(categories.first.name, 'Verduras');
      expect(categories.first.description, 'Productos frescos');
      expect(categories.last.id, 'cat-2');
      expect(categories.last.name, 'Frutas');
      expect(categories.last.description, '');
    });

    test(
      'devuelve una lista vacía cuando el servidor responde vacío',
      () async {
        final MockClient mockClient = MockClient(
          (http.Request request) async => http.Response('{}', 200),
        );

        expect(await buildRepository(mockClient).fetchCategories(), isEmpty);
      },
    );
  });

  group('CatalogItem imageSrc', () {
    test('devuelve la URL absoluta tal cual', () {
      final CatalogItem item = CatalogItem.fromJson(<String, dynamic>{
        'image_url': 'https://cdn.milpa.com/fotos/tomate.jpg',
      });

      expect(item.imageSrc, 'https://cdn.milpa.com/fotos/tomate.jpg');
    });

    test('resuelve una ruta relativa contra el endpoint de imágenes', () {
      final CatalogItem item = CatalogItem.fromJson(<String, dynamic>{
        'image_url': 'uploads/tomate.jpg',
      });

      expect(item.imageSrc, '${ApiConfig.apiBaseUrl}/images/tomate.jpg');
    });

    test('devuelve null cuando image_url está vacío', () {
      final CatalogItem item = CatalogItem.fromJson(<String, dynamic>{
        'image_url': '',
      });

      expect(item.imageSrc, isNull);
    });

    test('usa valores por defecto cuando faltan campos', () {
      final CatalogItem item = CatalogItem.fromJson(<String, dynamic>{});

      expect(item.id, '');
      expect(item.price, 0);
      expect(item.farmerVerified, isFalse);
      expect(item.imageUrl, '');
      expect(item.imageSrc, isNull);
    });
  });

  group('formatPrice', () {
    test('usa separador de miles sin decimales para montos enteros', () {
      expect(formatPrice(3800), 'C\$ 3.800');
      expect(formatPrice(25), 'C\$ 25');
    });

    test('usa coma y dos decimales cuando el monto no es entero', () {
      expect(formatPrice(3800.5), 'C\$ 3.800,50');
    });
  });
}
