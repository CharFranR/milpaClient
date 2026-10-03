import 'dart:convert';

import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/models/auth_models.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/auth/auth_repository.dart';
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

AuthRepository buildRepository(MockClient mockClient, FakeTokenStore store) =>
    AuthRepository(
      apiClient: ApiClient(httpClient: mockClient),
      tokenStore: store,
    );

void main() {
  group('AuthRepository login', () {
    test(
      'envía las credenciales, parsea el envelope y guarda la sesión',
      () async {
        Map<String, dynamic>? sentBody;
        final MockClient mockClient = MockClient((http.Request request) async {
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode(<String, dynamic>{
              'data': <String, dynamic>{
                'access_token': 'token-123',
                'expires_in': 86400,
                'user': <String, dynamic>{
                  'id': 'user-1',
                  'email': 'a@b.com',
                  'first_name': 'Flutter',
                  'last_name': 'Test',
                  'role': 2,
                  'department': '',
                  'municipality': '',
                  'phone_number': '+50588887777',
                  'address_line': '',
                  'created_at': '2026-01-01T00:00:00Z',
                  'updated_at': '2026-01-01T00:00:00Z',
                },
              },
            }),
            200,
          );
        });
        final FakeTokenStore store = FakeTokenStore();

        final User user = await buildRepository(
          mockClient,
          store,
        ).login(email: 'a@b.com', password: 'secret');

        expect(sentBody, <String, dynamic>{
          'email': 'a@b.com',
          'password': 'secret',
        });
        expect(user.id, 'user-1');
        expect(user.firstName, 'Flutter');
        expect(store.values['token'], 'token-123');
        expect(store.values['userId'], 'user-1');
      },
    );

    test('lanza ApiException 401 y no guarda nada cuando rechaza', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async =>
            http.Response('{"error":"unauthorized"}', 401),
      );
      final FakeTokenStore store = FakeTokenStore();

      await expectLater(
        buildRepository(
          mockClient,
          store,
        ).login(email: 'a@b.com', password: 'bad'),
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
                'unauthorized',
              ),
        ),
      );
      expect(store.values, isEmpty);
    });
  });

  group('AuthRepository register', () {
    test(
      'envía phone_number y role entero y devuelve el usuario parseado',
      () async {
        Map<String, dynamic>? sentBody;
        final MockClient mockClient = MockClient((http.Request request) async {
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode(<String, dynamic>{
              'data': <String, dynamic>{
                'id': 'user-2',
                'email': 'nuevo@milpa.com',
                'first_name': 'Ana',
                'last_name': 'Lopez',
                'role': 1,
                'department': 'Managua',
                'municipality': 'Tipitapa',
                'phone_number': '+50577778888',
                'address_line': 'Km 5',
                'created_at': '2026-01-01T00:00:00Z',
                'updated_at': '2026-01-01T00:00:00Z',
              },
            }),
            201,
          );
        });
        final FakeTokenStore store = FakeTokenStore();

        final User user = await buildRepository(mockClient, store).register(
          email: 'nuevo@milpa.com',
          firstName: 'Ana',
          lastName: 'Lopez',
          phoneNumber: '+50577778888',
          role: 1,
          password: 'secret',
          confirmPassword: 'secret',
          address: 'Km 5',
          department: 'Managua',
          municipality: 'Tipitapa',
        );

        expect(sentBody!['phone_number'], '+50577778888');
        expect(sentBody!['role'], 1);
        expect(sentBody!['role'], isA<int>());
        expect(user.id, 'user-2');
        expect(user.role, 1);
        expect(user.addressLine, 'Km 5');
        expect(user.department, 'Managua');
        expect(user.municipality, 'Tipitapa');
      },
    );
  });

  group('AuthRepository restoreSession', () {
    test('devuelve token y userId cuando ambos están guardados', () async {
      final FakeTokenStore store = FakeTokenStore();
      await store.save(token: 'token-abc', userId: 'user-abc');
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response('{}', 200),
      );

      final ({String token, String userId})? session = await buildRepository(
        mockClient,
        store,
      ).restoreSession();

      expect(session, isNotNull);
      expect(session!.token, 'token-abc');
      expect(session.userId, 'user-abc');
    });

    test('devuelve null cuando falta el token o el userId', () async {
      final FakeTokenStore store = FakeTokenStore();
      final AuthRepository repository = buildRepository(
        MockClient((http.Request request) async => http.Response('{}', 200)),
        store,
      );

      expect(await repository.restoreSession(), isNull);

      store.values['token'] = 'token-abc';
      expect(await repository.restoreSession(), isNull);

      store.values.remove('token');
      store.values['userId'] = 'user-abc';
      expect(await repository.restoreSession(), isNull);
    });
  });

  group('AuthRepository logout', () {
    test('limpia el almacenamiento de la sesión', () async {
      final FakeTokenStore store = FakeTokenStore();
      await store.save(token: 'token-abc', userId: 'user-abc');
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response('{}', 200),
      );

      await buildRepository(mockClient, store).logout();

      expect(store.values, isEmpty);
    });
  });

  group('User.fromJson', () {
    test('mapea address a addressLine cuando no viene address_line', () {
      final User user = User.fromJson(<String, dynamic>{
        'id': 'user-9',
        'email': 'a@b.com',
        'first_name': 'Flutter',
        'last_name': 'Test',
        'phone_number': '+50588887777',
        'role': 2,
        'address': 'Km 10',
      });

      expect(user.addressLine, 'Km 10');
      expect(user.department, '');
      expect(user.municipality, '');
      expect(user.createdAt, isNull);
      expect(user.updatedAt, isNull);
    });

    test('usa valores por defecto cuando faltan campos', () {
      final User user = User.fromJson(<String, dynamic>{});

      expect(user.id, '');
      expect(user.email, '');
      expect(user.firstName, '');
      expect(user.lastName, '');
      expect(user.phoneNumber, '');
      expect(user.role, 0);
      expect(user.department, '');
      expect(user.municipality, '');
      expect(user.addressLine, '');
    });
  });
}
