import 'dart:convert';

import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient respuestas exitosas', () {
    test('GET con 200 y objeto JSON devuelve el Map decodificado', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async =>
            http.Response('{"id": 7, "nombre": "maiz"}', 200),
      );

      final dynamic result = await ApiClient(httpClient: mockClient)
          .get('/products/7');

      expect(result, <String, dynamic>{'id': 7, 'nombre': 'maiz'});
    });

    test('GET con 200 y arreglo JSON devuelve el List decodificado', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async =>
            http.Response('[{"id": 1}, {"id": 2}]', 200),
      );

      final dynamic result = await ApiClient(httpClient: mockClient)
          .get('/products');

      expect(result, <dynamic>[
        <String, dynamic>{'id': 1},
        <String, dynamic>{'id': 2},
      ]);
    });

    test('POST con 201 y cuerpo vacío devuelve null', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response('', 201),
      );

      final dynamic result = await ApiClient(httpClient: mockClient)
          .post('/products', body: <String, dynamic>{'nombre': 'maiz'});

      expect(result, isNull);
    });
  });

  group('ApiClient errores del servidor', () {
    test(
      'GET 401 lanza ApiException con el status y el mensaje del servidor',
      () async {
        final MockClient mockClient = MockClient(
          (http.Request request) async =>
              http.Response('{"error":"invalid credentials"}', 401),
        );

        await expectLater(
          ApiClient(httpClient: mockClient).get('/auth/me'),
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
                  'invalid credentials',
                ),
          ),
        );
      },
    );

    test(
      'POST 409 lanza ApiException con el status y el mensaje del servidor',
      () async {
        final MockClient mockClient = MockClient(
          (http.Request request) async =>
              http.Response('{"error":"email taken"}', 409),
        );

        await expectLater(
          ApiClient(httpClient: mockClient).post(
            '/auth/register',
            body: <String, dynamic>{'email': 'juan@milpa.com'},
          ),
          throwsA(
            isA<ApiException>()
                .having(
                  (ApiException error) => error.statusCode,
                  'statusCode',
                  409,
                )
                .having(
                  (ApiException error) => error.message,
                  'message',
                  'email taken',
                ),
          ),
        );
      },
    );

    test('un error sin JSON usa el mensaje genérico del servidor', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response('boom', 500),
      );

      await expectLater(
        ApiClient(httpClient: mockClient).get('/products'),
        throwsA(
          isA<ApiException>()
              .having(
                (ApiException error) => error.statusCode,
                'statusCode',
                500,
              )
              .having(
                (ApiException error) => error.message,
                'message',
                'Error inesperado del servidor',
              ),
        ),
      );
    });
  });

  group('ApiClient fallas de red', () {
    test('un ClientException se convierte en NetworkException', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async =>
            throw http.ClientException('conexión interrumpida'),
      );

      await expectLater(
        ApiClient(httpClient: mockClient).get('/products'),
        throwsA(isA<NetworkException>()),
      );
    });

    test(
      'un timeout se convierte en NetworkException con mensaje propio',
      () async {
        final MockClient mockClient = MockClient((http.Request request) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return http.Response('{}', 200);
        });

        await expectLater(
          ApiClient(
            httpClient: mockClient,
            timeout: const Duration(milliseconds: 10),
          ).get('/products'),
          throwsA(
            isA<NetworkException>().having(
              (NetworkException error) => error.message,
              'message',
              'El servidor tardó demasiado en responder',
            ),
          ),
        );
      },
    );
  });

  group('ApiClient autenticación', () {
    test('adjunta Authorization Bearer cuando se pasa token', () async {
      String? authorization;
      final MockClient mockClient = MockClient((http.Request request) async {
        authorization = request.headers['Authorization'];
        return http.Response('{}', 200);
      });

      await ApiClient(httpClient: mockClient).get('/auth/me', token: 'abc123');

      expect(authorization, 'Bearer abc123');
    });

    test('no adjunta Authorization cuando no se pasa token', () async {
      bool hasAuthorization = true;
      final MockClient mockClient = MockClient((http.Request request) async {
        hasAuthorization = request.headers.containsKey('Authorization');
        return http.Response('{}', 200);
      });

      await ApiClient(httpClient: mockClient).get('/products');

      expect(hasAuthorization, isFalse);
    });
  });

  group('ApiClient envío de cuerpo', () {
    test(
      'POST envía el cuerpo como JSON con Content-Type application/json',
      () async {
        String? sentBody;
        String? contentType;
        final MockClient mockClient = MockClient((http.Request request) async {
          sentBody = request.body;
          contentType = request.headers['Content-Type'];
          return http.Response('{"id": 1}', 201);
        });

        await ApiClient(httpClient: mockClient)
            .post('/products', body: <String, dynamic>{'nombre': 'maiz'});

        expect(jsonDecode(sentBody!), <String, dynamic>{'nombre': 'maiz'});
        expect(contentType, contains('application/json'));
      },
    );
  });
}
