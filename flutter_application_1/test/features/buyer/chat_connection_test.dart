import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/features/buyer/chat_connection.dart';
import 'package:flutter_application_1/features/buyer/conversation_models.dart';
import 'package:flutter_test/flutter_test.dart';

const Duration testTimeout = Duration(seconds: 5);

class TestChatServer {
  TestChatServer._(this._server) {
    _server.listen(_handleRequest);
  }

  static Future<TestChatServer> start() async {
    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    return TestChatServer._(server);
  }

  final HttpServer _server;
  final List<String> requestedProtocols = <String>[];
  final StreamController<dynamic> _incomingController =
      StreamController<dynamic>.broadcast();
  final Completer<WebSocket> _socketReady = Completer<WebSocket>();

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final WebSocket socket = await WebSocketTransformer.upgrade(
        request,
        protocolSelector: (List<String> protocols) {
          requestedProtocols.addAll(protocols);
          return protocols.isEmpty ? null : protocols.first;
        },
      );
      socket.listen(
        _incomingController.add,
        onError: _incomingController.addError,
        onDone: _incomingController.close,
      );
      if (!_socketReady.isCompleted) {
        _socketReady.complete(socket);
      }
    } catch (error, stackTrace) {
      if (!_socketReady.isCompleted) {
        _socketReady.completeError(error, stackTrace);
      }
    }
  }

  Uri get uri =>
      Uri.parse('ws://127.0.0.1:${_server.port}/api/v1/ws/conversation-1');

  Future<WebSocket> get socket => _socketReady.future.timeout(testTimeout);

  Stream<dynamic> get incoming => _incomingController.stream;

  Future<void> close() async {
    if (_socketReady.isCompleted) {
      await (await _socketReady.future).close();
    }
    await _server.close(force: true);
  }
}

Future<WebSocketChatConnection> connectTo(TestChatServer server) async {
  final WebSocketChatConnection connection = WebSocketChatConnection(
    uri: server.uri,
    token: 'token-123',
  );
  await connection.status
      .firstWhere((bool value) => value)
      .timeout(testTimeout);
  return connection;
}

void main() {
  test('conecta, emite estado y negocia los subprotocolos', () async {
    final TestChatServer server = await TestChatServer.start();
    addTearDown(server.close);
    final WebSocketChatConnection connection = await connectTo(server);
    addTearDown(connection.close);

    expect(connection.isConnected, isTrue);
    await server.socket;
    expect(server.requestedProtocols, <String>[
      'milpa.chat.v1',
      'bearer.token-123',
    ]);
  });

  test('parsea un frame JSON del servidor como ChatMessage', () async {
    final TestChatServer server = await TestChatServer.start();
    addTearDown(server.close);
    final WebSocketChatConnection connection = await connectTo(server);
    addTearDown(connection.close);

    final Future<ChatMessage> received = connection.messages.first.timeout(
      testTimeout,
    );
    final WebSocket socket = await server.socket;
    socket.add(
      jsonEncode(<String, dynamic>{
        'id': 'message-1',
        'conversation_id': 'conversation-1',
        'sender_id': 'user-1',
        'content': 'Hola, ¿está disponible?',
        'visibility': true,
        'created_at': '2026-01-01T00:00:00Z',
      }),
    );

    final ChatMessage message = await received;

    expect(message.id, 'message-1');
    expect(message.conversationId, 'conversation-1');
    expect(message.senderId, 'user-1');
    expect(message.content, 'Hola, ¿está disponible?');
    expect(message.visibility, isTrue);
    expect(message.createdAt, '2026-01-01T00:00:00Z');
    expect(message.isFromSponsor, isFalse);
  });

  test(
    'envía el contenido como frame de texto cuando está conectado',
    () async {
      final TestChatServer server = await TestChatServer.start();
      addTearDown(server.close);
      final WebSocketChatConnection connection = await connectTo(server);
      addTearDown(connection.close);

      final Future<dynamic> clientFrame = server.incoming.first.timeout(
        testTimeout,
      );

      connection.send('hola');

      expect(await clientFrame, 'hola');
    },
  );

  test('ignora un frame malformado sin cerrar el stream', () async {
    final TestChatServer server = await TestChatServer.start();
    addTearDown(server.close);
    final WebSocketChatConnection connection = await connectTo(server);
    addTearDown(connection.close);

    final Future<ChatMessage> received = connection.messages.first.timeout(
      testTimeout,
    );
    final WebSocket socket = await server.socket;
    socket.add('esto no es json');
    socket.add(
      jsonEncode(<String, dynamic>{
        'id': 'message-2',
        'conversation_id': 'conversation-1',
        'sender_id': 'user-1',
        'content': 'sigo vivo',
        'visibility': true,
        'created_at': '2026-01-01T00:00:00Z',
      }),
    );

    final ChatMessage message = await received;

    expect(message.id, 'message-2');
    expect(message.content, 'sigo vivo');
  });

  test('parsea el aviso de sponsor sin sender_id', () async {
    final TestChatServer server = await TestChatServer.start();
    addTearDown(server.close);
    final WebSocketChatConnection connection = await connectTo(server);
    addTearDown(connection.close);

    final Future<ChatMessage> received = connection.messages.first.timeout(
      testTimeout,
    );
    final WebSocket socket = await server.socket;
    socket.add(
      jsonEncode(<String, dynamic>{
        'id': 'notice-1',
        'content': 'Espacio disponible gracias a Hackaton Nicaragua',
      }),
    );

    final ChatMessage message = await received;

    expect(message.isFromSponsor, isTrue);
    expect(message.senderId, isNull);
    expect(message.content, 'Espacio disponible gracias a Hackaton Nicaragua');
    expect(message.conversationId, '');
  });

  test('cierra la conexión de forma limpia', () async {
    final TestChatServer server = await TestChatServer.start();
    addTearDown(server.close);
    final WebSocketChatConnection connection = await connectTo(server);
    await server.socket;

    await connection.close().timeout(testTimeout);

    expect(connection.isConnected, isFalse);
    await server.incoming.drain<void>().timeout(testTimeout);
  });
}
