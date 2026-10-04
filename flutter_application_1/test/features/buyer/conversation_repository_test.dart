import 'dart:convert';

import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/conversation_models.dart';
import 'package:flutter_application_1/features/buyer/conversation_repository.dart';
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

ConversationRepository buildRepository(
  MockClient mockClient,
  FakeTokenStore store,
) => ConversationRepository(
  apiClient: ApiClient(httpClient: mockClient),
  tokenStore: store,
);

FakeTokenStore storeWithToken() =>
    FakeTokenStore()..values['token'] = 'token-123';

void main() {
  group('ConversationRepository start', () {
    test('envía POST con cuerpo y Bearer, y parsea la conversación', () async {
      String? method;
      Uri? requestedUri;
      Map<String, dynamic>? sentBody;
      String? authorization;
      final MockClient mockClient = MockClient((http.Request request) async {
        method = request.method;
        requestedUri = request.url;
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        authorization = request.headers['Authorization'];
        return http.Response(
          jsonEncode(<String, dynamic>{
            'data': <String, dynamic>{
              'id': 'conversation-1',
              'farmer_id': 'farmer-1',
              'buyer_id': 'buyer-1',
              'offering_id': 'offering-1',
              'match_id': 'match-1',
              'visibility': true,
              'created_at': '2026-01-01T00:00:00Z',
              'updated_at': '2026-01-02T00:00:00Z',
            },
          }),
          201,
        );
      });

      final Conversation conversation = await buildRepository(
        mockClient,
        storeWithToken(),
      ).start(farmerId: 'farmer-1', offeringId: 'offering-1');

      expect(method, 'POST');
      expect(requestedUri!.path, '/api/v1/conversations');
      expect(sentBody, <String, dynamic>{
        'farmer_id': 'farmer-1',
        'offering_id': 'offering-1',
      });
      expect(authorization, 'Bearer token-123');
      expect(conversation.id, 'conversation-1');
      expect(conversation.farmerId, 'farmer-1');
      expect(conversation.buyerId, 'buyer-1');
      expect(conversation.offeringId, 'offering-1');
      expect(conversation.matchId, 'match-1');
      expect(conversation.visibility, isTrue);
      expect(conversation.createdAt, '2026-01-01T00:00:00Z');
      expect(conversation.updatedAt, '2026-01-02T00:00:00Z');
    });

    test('usa valores por defecto cuando faltan campos', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response(
          jsonEncode(<String, dynamic>{
            'data': <String, dynamic>{'id': 'conversation-2'},
          }),
          201,
        ),
      );

      final Conversation conversation = await buildRepository(
        mockClient,
        storeWithToken(),
      ).start(farmerId: 'farmer-1', offeringId: 'offering-1');

      expect(conversation.farmerId, '');
      expect(conversation.buyerId, '');
      expect(conversation.offeringId, '');
      expect(conversation.matchId, isNull);
      expect(conversation.visibility, isFalse);
      expect(conversation.createdAt, isNull);
      expect(conversation.updatedAt, isNull);
    });

    test('mapea 403 a ApiException con el mensaje del servidor', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response.bytes(
          utf8.encode(
            '{"error":"solo un comprador puede iniciar la conversación"}',
          ),
          403,
        ),
      );

      await expectLater(
        buildRepository(
          mockClient,
          storeWithToken(),
        ).start(farmerId: 'farmer-1', offeringId: 'offering-1'),
        throwsA(
          isA<ApiException>()
              .having(
                (ApiException error) => error.statusCode,
                'statusCode',
                403,
              )
              .having(
                (ApiException error) => error.message,
                'message',
                'solo un comprador puede iniciar la conversación',
              ),
        ),
      );
    });

    test('mapea 404 a ApiException con el mensaje del servidor', () async {
      final MockClient mockClient = MockClient(
        (http.Request request) async => http.Response.bytes(
          utf8.encode('{"error":"oferta no encontrada"}'),
          404,
        ),
      );

      await expectLater(
        buildRepository(
          mockClient,
          storeWithToken(),
        ).start(farmerId: 'farmer-1', offeringId: 'missing'),
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

    test(
      'lanza ApiException 401 sin llamar al servidor si falta el token',
      () async {
        bool calledServer = false;
        final MockClient mockClient = MockClient((http.Request request) async {
          calledServer = true;
          return http.Response('{}', 201);
        });

        await expectLater(
          buildRepository(
            mockClient,
            FakeTokenStore(),
          ).start(farmerId: 'farmer-1', offeringId: 'offering-1'),
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
        expect(calledServer, isFalse);
      },
    );
  });
}
