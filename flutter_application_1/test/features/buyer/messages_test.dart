import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/features/buyer/chat.dart';
import 'package:flutter_application_1/features/buyer/conversation_models.dart';
import 'package:flutter_application_1/features/buyer/messages.dart';
import 'package:flutter_application_1/features/buyer/offering_models.dart';

import '../../helpers/fake_conversation_repository.dart';
import '../../helpers/fake_offering_repository.dart';

Conversation buildConversation({
  String id = 'conversation-1',
  String farmerId = 'farmer-1',
  String buyerId = 'buyer-1',
  String offeringId = 'offering-1',
}) => Conversation(
  id: id,
  farmerId: farmerId,
  buyerId: buyerId,
  offeringId: offeringId,
  visibility: true,
);

ChatMessage buildMessage({
  String id = 'message-1',
  String conversationId = 'conversation-1',
  String? senderId,
  String content = 'Hola',
  String? createdAt = '2026-01-15T12:00:00Z',
}) => ChatMessage(
  id: id,
  conversationId: conversationId,
  senderId: senderId,
  content: content,
  visibility: true,
  createdAt: createdAt,
);

String dateLabel(String iso) {
  final DateTime local = DateTime.parse(iso).toLocal();
  final String day = local.day.toString().padLeft(2, '0');
  final String month = local.month.toString().padLeft(2, '0');
  return '$day/$month';
}

class MappedOfferingRepository extends FakeOfferingRepository {
  MappedOfferingRepository({
    required this.sellers,
    this.failingFarmerIds = const <String>{},
  });

  final Map<String, SellerProfile> sellers;
  final Set<String> failingFarmerIds;

  @override
  Future<SellerProfile> fetchSeller(String userId) async {
    sellerCalls++;
    lastSellerId = userId;
    if (failingFarmerIds.contains(userId)) {
      throw Exception('sin vendedor');
    }
    return sellers[userId] ?? seller;
  }
}

Widget wrap({
  required FakeConversationRepository repository,
  required FakeOfferingRepository offerings,
}) => MaterialApp(
  home: BuyerMessages(repository: repository, offeringRepository: offerings),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          secureStorageChannel,
          (MethodCall call) async => null,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  testWidgets('muestra el nombre del interlocutor y el último mensaje', (
    WidgetTester tester,
  ) async {
    final repository = FakeConversationRepository()
      ..conversations = <Conversation>[
        buildConversation(),
        buildConversation(
          id: 'conversation-2',
          farmerId: 'farmer-2',
          offeringId: 'offering-2',
        ),
      ]
      ..messagesByConversation.addAll(<String, List<ChatMessage>>{
        'conversation-1': <ChatMessage>[
          buildMessage(
            id: 'm1',
            content: 'Primer mensaje',
            createdAt: '2026-01-15T10:00:00Z',
          ),
          buildMessage(
            id: 'm2',
            senderId: 'buyer-1',
            content: 'Último mensaje',
            createdAt: '2026-01-15T11:00:00Z',
          ),
        ],
        'conversation-2': <ChatMessage>[
          buildMessage(
            id: 'm3',
            conversationId: 'conversation-2',
            senderId: 'farmer-2',
            content: 'Precio actualizado',
            createdAt: '2026-01-16T09:00:00Z',
          ),
        ],
      });
    final offerings = MappedOfferingRepository(
      sellers: const <String, SellerProfile>{
        'farmer-1': SellerProfile(
          id: 'farmer-1',
          firstName: 'María',
          lastName: 'López',
          role: 1,
          department: 'Matagalpa',
          municipality: 'Sebaco',
        ),
        'farmer-2': SellerProfile(
          id: 'farmer-2',
          firstName: 'Juan',
          lastName: 'Pérez',
          role: 1,
          department: 'Estelí',
          municipality: 'Condega',
        ),
      },
    );

    await tester.pumpWidget(wrap(repository: repository, offerings: offerings));
    await tester.pump();
    await tester.pump();

    expect(find.text('María López'), findsOneWidget);
    expect(find.text('Juan Pérez'), findsOneWidget);
    expect(find.text('Primer mensaje'), findsNothing);
    expect(find.text('Último mensaje'), findsOneWidget);
    expect(find.text('Precio actualizado'), findsOneWidget);
    expect(find.text(dateLabel('2026-01-15T11:00:00Z')), findsOneWidget);
    expect(find.text(dateLabel('2026-01-16T09:00:00Z')), findsOneWidget);
    expect(repository.fetchAllCalls, 1);
    expect(repository.fetchMessagesCalls, 2);
  });

  testWidgets('muestra el estado vacío cuando no hay conversaciones', (
    WidgetTester tester,
  ) async {
    final repository = FakeConversationRepository();

    await tester.pumpWidget(
      wrap(
        repository: repository,
        offerings: MappedOfferingRepository(sellers: const {}),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Todavía no tenés conversaciones'), findsOneWidget);
    expect(repository.fetchAllCalls, 1);
  });

  testWidgets('tolera el fallo de una conversación sin bloquear la bandeja', (
    WidgetTester tester,
  ) async {
    final repository = FakeConversationRepository()
      ..conversations = <Conversation>[
        buildConversation(),
        buildConversation(
          id: 'conversation-2',
          farmerId: 'farmer-2',
          offeringId: 'offering-2',
        ),
      ]
      ..messageErrorConversationIds = <String>{'conversation-1'}
      ..messagesByConversation['conversation-2'] = <ChatMessage>[
        buildMessage(
          id: 'm1',
          conversationId: 'conversation-2',
          senderId: 'farmer-2',
          content: 'Todo bien',
        ),
      ];
    final offerings = MappedOfferingRepository(
      sellers: const <String, SellerProfile>{
        'farmer-2': SellerProfile(
          id: 'farmer-2',
          firstName: 'Juan',
          lastName: 'Pérez',
          role: 1,
          department: 'Estelí',
          municipality: 'Condega',
        ),
      },
      failingFarmerIds: const <String>{'farmer-1'},
    );

    await tester.pumpWidget(wrap(repository: repository, offerings: offerings));
    await tester.pump();
    await tester.pump();

    expect(find.text('Productor'), findsOneWidget);
    expect(find.text('Sin mensajes aún'), findsOneWidget);
    expect(find.text('Juan Pérez'), findsOneWidget);
    expect(find.text('Todo bien'), findsOneWidget);
  });

  testWidgets('el error muestra Reintentar y al reintentar recarga', (
    WidgetTester tester,
  ) async {
    final repository = FakeConversationRepository()
      ..fetchAllError = Exception('sin conexión');

    await tester.pumpWidget(
      wrap(
        repository: repository,
        offerings: MappedOfferingRepository(sellers: const {}),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Todavía no tenés conversaciones'), findsNothing);

    repository.fetchAllError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Reintentar'), findsNothing);
    expect(find.text('Todavía no tenés conversaciones'), findsOneWidget);
    expect(repository.fetchAllCalls, 2);
  });

  testWidgets('al tocar una conversación navega al chat', (
    WidgetTester tester,
  ) async {
    final repository = FakeConversationRepository()
      ..conversations = <Conversation>[buildConversation()]
      ..messagesByConversation['conversation-1'] = <ChatMessage>[
        buildMessage(id: 'm1', senderId: 'farmer-1', content: 'Hola'),
      ];
    final offerings = MappedOfferingRepository(
      sellers: const <String, SellerProfile>{
        'farmer-1': SellerProfile(
          id: 'farmer-1',
          firstName: 'María',
          lastName: 'López',
          role: 1,
          department: 'Matagalpa',
          municipality: 'Sebaco',
        ),
      },
    );

    await tester.pumpWidget(wrap(repository: repository, offerings: offerings));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('María López'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(BuyerChat), findsOneWidget);
  });
}
