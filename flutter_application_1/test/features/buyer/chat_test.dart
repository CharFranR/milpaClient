import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/features/buyer/chat.dart';
import 'package:flutter_application_1/features/buyer/conversation_models.dart';

import '../../helpers/fake_chat_connection.dart';
import '../../helpers/fake_conversation_repository.dart';

ChatMessage buildMessage({
  String id = 'message-1',
  String? senderId,
  String content = 'Hola',
  String? createdAt = '2026-01-15T12:00:00Z',
}) => ChatMessage(
  id: id,
  conversationId: 'conversation-1',
  senderId: senderId,
  content: content,
  visibility: true,
  createdAt: createdAt,
);

String hourLabel(String iso) {
  final DateTime local = DateTime.parse(iso).toLocal();
  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

Widget wrap({
  required FakeConversationRepository repository,
  required FakeChatConnection connection,
  String currentUserId = 'buyer-1',
}) => MaterialApp(
  home: BuyerChat(
    conversationId: 'conversation-1',
    counterpartName: 'María López',
    repository: repository,
    connection: connection,
    currentUserId: currentUserId,
  ),
);

void main() {
  testWidgets(
    'muestra el historial propio, ajeno y el aviso del patrocinador',
    (WidgetTester tester) async {
      final repository = FakeConversationRepository()
        ..messagesByConversation['conversation-1'] = <ChatMessage>[
          buildMessage(
            id: 'm2',
            senderId: 'farmer-1',
            content: 'Buenos días',
            createdAt: '2026-01-15T10:05:00Z',
          ),
          buildMessage(
            id: 'm1',
            senderId: 'buyer-1',
            content: 'Buenos días, sí',
            createdAt: '2026-01-15T10:00:00Z',
          ),
          buildMessage(
            id: 'm3',
            content: 'Espacio disponible gracias a Hackaton Nicaragua',
            createdAt: '2026-01-15T10:10:00Z',
          ),
        ];
      final connection = FakeChatConnection();

      await tester.pumpWidget(
        wrap(repository: repository, connection: connection),
      );
      await tester.pump();

      expect(find.text('Buenos días'), findsOneWidget);
      expect(find.text('Buenos días, sí'), findsOneWidget);
      expect(
        find.text('Espacio disponible gracias a Hackaton Nicaragua'),
        findsOneWidget,
      );
      expect(find.text(hourLabel('2026-01-15T10:05:00Z')), findsOneWidget);
      expect(find.text('María López'), findsOneWidget);
      expect(find.text('En línea'), findsOneWidget);
      expect(repository.fetchMessagesCalls, 1);
      expect(repository.lastFetchedConversationId, 'conversation-1');
    },
  );

  testWidgets('una desconección muestra Sin conexión en la cabecera', (
    WidgetTester tester,
  ) async {
    final repository = FakeConversationRepository();
    final connection = FakeChatConnection();

    await tester.pumpWidget(
      wrap(repository: repository, connection: connection),
    );
    await tester.pump();

    connection.emitStatus(false);
    await tester.pump();

    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.text('En línea'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('un mensaje entrante en vivo se agrega a la conversación', (
    WidgetTester tester,
  ) async {
    final repository = FakeConversationRepository();
    final connection = FakeChatConnection();

    await tester.pumpWidget(
      wrap(repository: repository, connection: connection),
    );
    await tester.pump();

    connection.emitMessage(
      buildMessage(
        id: 'live-1',
        senderId: 'farmer-1',
        content: '¿Sigue en pie?',
      ),
    );
    await tester.pump();

    expect(find.text('¿Sigue en pie?'), findsOneWidget);
  });

  testWidgets('un mensaje en vivo con id repetido se ignora', (
    WidgetTester tester,
  ) async {
    final repository = FakeConversationRepository()
      ..messagesByConversation['conversation-1'] = <ChatMessage>[
        buildMessage(
          id: 'm1',
          senderId: 'farmer-1',
          content: 'Buenos días',
          createdAt: '2026-01-15T10:00:00Z',
        ),
      ];
    final connection = FakeChatConnection();

    await tester.pumpWidget(
      wrap(repository: repository, connection: connection),
    );
    await tester.pump();

    connection.emitMessage(
      buildMessage(
        id: 'm1',
        senderId: 'farmer-1',
        content: 'Buenos días',
        createdAt: '2026-01-15T10:00:00Z',
      ),
    );
    await tester.pump();

    expect(find.text('Buenos días'), findsOneWidget);
  });

  testWidgets('enviar conectado usa la conexión sin llamar al repositorio', (
    WidgetTester tester,
  ) async {
    final repository = FakeConversationRepository();
    final connection = FakeChatConnection();

    await tester.pumpWidget(
      wrap(repository: repository, connection: connection),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), '¿Cuánto cuesta?');
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pump();

    expect(connection.sentContents, <String>['¿Cuánto cuesta?']);
    expect(repository.sendMessageCalls, 0);
    expect(find.text('¿Cuánto cuesta?'), findsNothing);
  });

  testWidgets('enviar desconectado persiste y recarga el historial', (
    WidgetTester tester,
  ) async {
    final repository = FakeConversationRepository();
    final connection = FakeChatConnection(connected: false);

    await tester.pumpWidget(
      wrap(repository: repository, connection: connection),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Hola productor');
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pump();
    await tester.pump();

    expect(connection.sentContents, isEmpty);
    expect(repository.sendMessageCalls, 1);
    expect(repository.lastSendConversationId, 'conversation-1');
    expect(repository.lastSendContent, 'Hola productor');
    expect(repository.fetchMessagesCalls, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('un envío fallido muestra el aviso', (WidgetTester tester) async {
    final repository = FakeConversationRepository()
      ..sendMessageError = Exception('sin conexión');
    final connection = FakeChatConnection(connected: false);

    await tester.pumpWidget(
      wrap(repository: repository, connection: connection),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Hola productor');
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pump();
    await tester.pump();

    expect(find.text('No se pudo enviar el mensaje'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('el error de historial muestra Reintentar y recarga', (
    WidgetTester tester,
  ) async {
    final repository = FakeConversationRepository()
      ..fetchMessagesError = Exception('sin conexión');
    final connection = FakeChatConnection();

    await tester.pumpWidget(
      wrap(repository: repository, connection: connection),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Reintentar'), findsOneWidget);

    repository.fetchMessagesError = null;
    repository.messagesByConversation['conversation-1'] = <ChatMessage>[
      buildMessage(id: 'm1', senderId: 'farmer-1', content: 'Hola de nuevo'),
    ];

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Reintentar'), findsNothing);
    expect(find.text('Hola de nuevo'), findsOneWidget);
    expect(repository.fetchMessagesCalls, 2);
  });

  testWidgets('una reconexión recarga el historial y apaga el reintento', (
    WidgetTester tester,
  ) async {
    final repository = FakeConversationRepository()
      ..messagesByConversation['conversation-1'] = <ChatMessage>[
        buildMessage(id: 'm1', senderId: 'farmer-1', content: 'Hola'),
      ];
    final connection = FakeChatConnection();

    await tester.pumpWidget(
      wrap(repository: repository, connection: connection),
    );
    await tester.pump();

    connection.emitStatus(false);
    await tester.pump();

    expect(find.text('Sin conexión'), findsOneWidget);

    repository.messagesByConversation['conversation-1'] = <ChatMessage>[
      buildMessage(id: 'm1', senderId: 'farmer-1', content: 'Hola'),
      buildMessage(
        id: 'm2',
        senderId: 'farmer-1',
        content: 'Mensaje perdido',
        createdAt: '2026-01-15T13:00:00Z',
      ),
    ];

    connection.emitStatus(true);
    await tester.pump();
    await tester.pump();

    expect(find.text('En línea'), findsOneWidget);
    expect(find.text('Mensaje perdido'), findsOneWidget);
    expect(repository.fetchMessagesCalls, 2);
  });

  testWidgets('al desmontar se cierra la conexión', (
    WidgetTester tester,
  ) async {
    final repository = FakeConversationRepository();
    final connection = FakeChatConnection();

    await tester.pumpWidget(
      wrap(repository: repository, connection: connection),
    );
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(connection.closeCalls, 1);
  });

  testWidgets('desconectado el reintento periódico no deja temporizadores', (
    WidgetTester tester,
  ) async {
    final repository = FakeConversationRepository();
    final connection = FakeChatConnection();

    await tester.pumpWidget(
      wrap(repository: repository, connection: connection),
    );
    await tester.pump();

    connection.emitStatus(false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    expect(find.text('Sin conexión'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(connection.closeCalls, 1);
  });
}
