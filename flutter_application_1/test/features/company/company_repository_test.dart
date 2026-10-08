import 'dart:convert';

import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/company/company_models.dart';
import 'package:flutter_application_1/features/company/company_repository.dart';
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

CompanyRepository buildRepository(
  MockClient mockClient,
  FakeTokenStore store,
) => CompanyRepository(
  apiClient: ApiClient(httpClient: mockClient),
  tokenStore: store,
);

FakeTokenStore storeWithToken() =>
    FakeTokenStore()..values['token'] = 'token-123';

http.Response jsonResponse(Object? body, {int status = 200}) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

Map<String, dynamic> companyJson({
  String id = 'company-1',
  String name = 'Finca El Roble',
  String categoryId = 'cat-1',
  String ownerId = 'owner-1',
  String department = 'Matagalpa',
  String municipality = 'San Ramón',
  String description = 'Café de altura',
  String website = 'https://finca.com',
  bool verified = true,
  String? email,
  String? phoneNumber,
  String? addressLine,
}) => <String, dynamic>{
  'id': id,
  'name': name,
  'category_id': categoryId,
  'owner_id': ownerId,
  'department': department,
  'municipality': municipality,
  'description': description,
  'website': website,
  'verified': verified,
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-02T00:00:00Z',
  'email': ?email,
  'phone_number': ?phoneNumber,
  'address_line': ?addressLine,
};

void main() {
  group('Company.fromJson', () {
    test('parsea los campos públicos y privados del DTO', () {
      final Company company = Company.fromJson(
        companyJson(
          email: 'finca@milpa.com',
          phoneNumber: '8888-8888',
          addressLine: 'Km 12 carretera',
        ),
      );

      expect(company.id, 'company-1');
      expect(company.name, 'Finca El Roble');
      expect(company.categoryId, 'cat-1');
      expect(company.ownerId, 'owner-1');
      expect(company.department, 'Matagalpa');
      expect(company.municipality, 'San Ramón');
      expect(company.description, 'Café de altura');
      expect(company.website, 'https://finca.com');
      expect(company.verified, isTrue);
      expect(company.createdAt, '2026-01-01T00:00:00Z');
      expect(company.updatedAt, '2026-01-02T00:00:00Z');
      expect(company.email, 'finca@milpa.com');
      expect(company.phoneNumber, '8888-8888');
      expect(company.addressLine, 'Km 12 carretera');
    });

    test('tolera campos ausentes', () {
      final Company company = Company.fromJson(<String, dynamic>{});

      expect(company.id, '');
      expect(company.name, '');
      expect(company.categoryId, '');
      expect(company.ownerId, '');
      expect(company.department, '');
      expect(company.municipality, '');
      expect(company.description, '');
      expect(company.website, '');
      expect(company.verified, isFalse);
      expect(company.createdAt, isNull);
      expect(company.updatedAt, isNull);
      expect(company.email, isNull);
      expect(company.phoneNumber, isNull);
      expect(company.addressLine, isNull);
    });
  });

  group('CompanyDraft.toJson', () {
    test('incluye solo los campos con valor y nunca la dirección', () {
      const CompanyDraft draft = CompanyDraft(
        name: 'Finca El Roble',
        categoryId: 'cat-1',
        description: 'Café de altura',
        phoneNumber: '8888-8888',
        email: 'finca@milpa.com',
        website: 'https://finca.com',
      );

      expect(draft.toJson(), <String, dynamic>{
        'name': 'Finca El Roble',
        'category_id': 'cat-1',
        'description': 'Café de altura',
        'phone_number': '8888-8888',
        'email': 'finca@milpa.com',
        'website': 'https://finca.com',
      });
    });

    test('omite category_id y los campos vacíos pero conserva name', () {
      const CompanyDraft draft = CompanyDraft(
        name: 'Finca El Roble',
        description: '   ',
        phoneNumber: '',
        email: '',
        website: '',
      );

      expect(draft.toJson(), <String, dynamic>{'name': 'Finca El Roble'});
    });
  });

  group('CompanyRepository fetchByOwner', () {
    test('envía GET con owner_id y parsea la lista', () async {
      String? method;
      Uri? requestedUri;
      bool hasAuthorization = true;
      final MockClient mockClient = MockClient((http.Request request) async {
        method = request.method;
        requestedUri = request.url;
        hasAuthorization = request.headers.containsKey('Authorization');
        return jsonResponse(<String, dynamic>{
          'data': <Map<String, dynamic>>[companyJson()],
        });
      });

      final List<Company> companies = await buildRepository(
        mockClient,
        FakeTokenStore(),
      ).fetchByOwner('owner-1');

      expect(method, 'GET');
      expect(requestedUri!.path, '/api/v1/companies');
      expect(requestedUri!.queryParameters, <String, String>{
        'owner_id': 'owner-1',
      });
      expect(hasAuthorization, isFalse);
      expect(companies, hasLength(1));
      expect(companies.single.id, 'company-1');
      expect(companies.single.name, 'Finca El Roble');
      expect(companies.single.ownerId, 'owner-1');
    });

    test(
      'devuelve una lista vacía cuando el servidor responde vacío',
      () async {
        final MockClient mockClient = MockClient(
          (http.Request request) async => http.Response('{}', 200),
        );

        expect(
          await buildRepository(
            mockClient,
            FakeTokenStore(),
          ).fetchByOwner('owner-1'),
          isEmpty,
        );
      },
    );
  });

  group('CompanyRepository fetchById', () {
    test('envía GET a /companies/{id} y parsea la empresa', () async {
      Uri? requestedUri;
      final MockClient mockClient = MockClient((http.Request request) async {
        requestedUri = request.url;
        return jsonResponse(<String, dynamic>{
          'data': companyJson(
            email: 'finca@milpa.com',
            phoneNumber: '8888-8888',
            addressLine: 'Km 12 carretera',
          ),
        });
      });

      final Company company = await buildRepository(
        mockClient,
        FakeTokenStore(),
      ).fetchById('company-1');

      expect(requestedUri!.path, '/api/v1/companies/company-1');
      expect(company.id, 'company-1');
      expect(company.email, 'finca@milpa.com');
      expect(company.phoneNumber, '8888-8888');
      expect(company.addressLine, 'Km 12 carretera');
    });

    test('mapea 404 a ApiException con el mensaje del servidor', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response.bytes(
          utf8.encode('{"error":"company not found"}'),
          404,
        ),
      );

      await expectLater(
        buildRepository(mockClient, FakeTokenStore()).fetchById('company-1'),
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
                'company not found',
              ),
        ),
      );
    });
  });

  group('CompanyRepository create', () {
    test(
      'envía POST con Bearer y el draft como cuerpo, y parsea la empresa',
      () async {
        String? method;
        Uri? requestedUri;
        Map<String, dynamic>? sentBody;
        String? authorization;
        final MockClient mockClient = MockClient((http.Request request) async {
          method = request.method;
          requestedUri = request.url;
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          authorization = request.headers['Authorization'];
          return jsonResponse(<String, dynamic>{
            'data': companyJson(),
          }, status: 201);
        });

        final Company company =
            await buildRepository(mockClient, storeWithToken()).create(
              const CompanyDraft(
                name: 'Finca El Roble',
                categoryId: 'cat-1',
                description: 'Café de altura',
                phoneNumber: '8888-8888',
                email: 'finca@milpa.com',
                website: 'https://finca.com',
              ),
            );

        expect(method, 'POST');
        expect(requestedUri!.path, '/api/v1/companies');
        expect(authorization, 'Bearer token-123');
        expect(sentBody, <String, dynamic>{
          'name': 'Finca El Roble',
          'category_id': 'cat-1',
          'description': 'Café de altura',
          'phone_number': '8888-8888',
          'email': 'finca@milpa.com',
          'website': 'https://finca.com',
        });
        expect(sentBody!.containsKey('address'), isFalse);
        expect(company.id, 'company-1');
        expect(company.name, 'Finca El Roble');
      },
    );

    test('lanza ApiException 401 cuando no hay token', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response('{}', 201),
      );

      await expectLater(
        buildRepository(
          mockClient,
          FakeTokenStore(),
        ).create(const CompanyDraft(name: 'Finca El Roble')),
        throwsA(
          isA<ApiException>()
              .having(
                (ApiException error) => error.statusCode,
                'statusCode',
                401,
              )
              .having(
                (ApiException error) => error.message,
                'message',
                'Sesión no disponible',
              ),
        ),
      );
    });

    test('mapea 400 a ApiException con el mensaje del servidor', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response.bytes(
          utf8.encode('{"error":"invalid company name"}'),
          400,
        ),
      );

      await expectLater(
        buildRepository(
          mockClient,
          storeWithToken(),
        ).create(const CompanyDraft(name: '')),
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
                'invalid company name',
              ),
        ),
      );
    });
  });

  group('CompanyRepository update', () {
    test('envía PATCH con Bearer y omite los campos vacíos', () async {
      String? method;
      Uri? requestedUri;
      Map<String, dynamic>? sentBody;
      String? authorization;
      final MockClient mockClient = MockClient((http.Request request) async {
        method = request.method;
        requestedUri = request.url;
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        authorization = request.headers['Authorization'];
        return http.Response('{}', 200);
      });

      await buildRepository(
        mockClient,
        storeWithToken(),
      ).update('company-1', const CompanyDraft(name: 'Finca El Roble'));

      expect(method, 'PATCH');
      expect(requestedUri!.path, '/api/v1/companies/company-1');
      expect(authorization, 'Bearer token-123');
      expect(sentBody, <String, dynamic>{'name': 'Finca El Roble'});
    });

    test('lanza ApiException 401 cuando no hay token', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response('{}', 200),
      );

      await expectLater(
        buildRepository(
          mockClient,
          FakeTokenStore(),
        ).update('company-1', const CompanyDraft(name: 'Finca El Roble')),
        throwsA(
          isA<ApiException>()
              .having(
                (ApiException error) => error.statusCode,
                'statusCode',
                401,
              )
              .having(
                (ApiException error) => error.message,
                'message',
                'Sesión no disponible',
              ),
        ),
      );
    });
  });
}
