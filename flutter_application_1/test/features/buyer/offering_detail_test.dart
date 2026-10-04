import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/features/buyer/chat.dart';
import 'package:flutter_application_1/features/buyer/conversation_models.dart';
import 'package:flutter_application_1/features/buyer/offering_detail.dart';
import 'package:flutter_application_1/features/buyer/offering_models.dart';

import '../../helpers/fake_conversation_repository.dart';
import '../../helpers/fake_offering_repository.dart';

Widget wrap({
  required FakeOfferingRepository offerings,
  required FakeConversationRepository conversations,
}) => MaterialApp(
  home: OfferingDetailPage(
    offeringId: 'offering-1',
    offeringRepository: offerings,
    conversationRepository: conversations,
  ),
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

  testWidgets('carga y muestra nombre, precio, vendedor, ubicación y reseñas', (
    WidgetTester tester,
  ) async {
    final offerings = FakeOfferingRepository();
    final conversations = FakeConversationRepository();

    await tester.pumpWidget(
      wrap(offerings: offerings, conversations: conversations),
    );
    await tester.pump();

    expect(find.text('Tomate cherry'), findsOneWidget);
    expect(find.text('Producto'), findsOneWidget);
    expect(find.text('C\$ 25,50'), findsOneWidget);
    expect(find.text('Cosecha de la semana'), findsOneWidget);
    expect(find.text('María López'), findsOneWidget);
    expect(find.text('Sebaco, Matagalpa'), findsOneWidget);
    expect(find.text('4.5 (12)'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(4));
    expect(find.byIcon(Icons.star_half), findsOneWidget);
    expect(offerings.detailCalls, 1);
    expect(offerings.lastDetailId, 'offering-1');
    expect(offerings.sellerCalls, 1);
    expect(offerings.lastSellerId, 'farmer-1');
    expect(offerings.ratingCalls, 1);
    expect(offerings.lastRatingId, 'farmer-1');
  });

  testWidgets('muestra el chip Servicio cuando el tipo es uno', (
    WidgetTester tester,
  ) async {
    final offerings = FakeOfferingRepository(
      detail: const OfferingDetail(
        id: 'offering-2',
        userId: 'farmer-2',
        type: 1,
        name: 'Asesoría de riego',
        description: '',
        price: 3800,
        imageUrl: '',
      ),
    );

    await tester.pumpWidget(
      wrap(offerings: offerings, conversations: FakeConversationRepository()),
    );
    await tester.pump();

    expect(find.text('Servicio'), findsOneWidget);
    expect(find.text('C\$ 3.800'), findsOneWidget);
    expect(find.text('Asesoría de riego'), findsOneWidget);
  });

  testWidgets('muestra Sin reseñas cuando el conteo es cero', (
    WidgetTester tester,
  ) async {
    final offerings = FakeOfferingRepository(
      rating: const RatingSummary(average: 0, count: 0),
    );

    await tester.pumpWidget(
      wrap(offerings: offerings, conversations: FakeConversationRepository()),
    );
    await tester.pump();

    expect(find.text('Sin reseñas'), findsOneWidget);
  });

  testWidgets('el error muestra Reintentar y al reintentar recarga', (
    WidgetTester tester,
  ) async {
    final offerings = FakeOfferingRepository()
      ..detailError = Exception('sin conexión');

    await tester.pumpWidget(
      wrap(offerings: offerings, conversations: FakeConversationRepository()),
    );
    await tester.pump();

    expect(find.text('No se pudo cargar la oferta'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    offerings.detailError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Reintentar'), findsNothing);
    expect(find.text('Tomate cherry'), findsOneWidget);
    expect(offerings.detailCalls, 2);
  });

  testWidgets('Chatear reutiliza la conversación existente y navega al chat', (
    WidgetTester tester,
  ) async {
    final offerings = FakeOfferingRepository();
    final conversations = FakeConversationRepository()
      ..conversations = <Conversation>[
        const Conversation(
          id: 'conversation-9',
          farmerId: 'farmer-1',
          buyerId: 'buyer-1',
          offeringId: 'offering-1',
          visibility: true,
        ),
      ];

    await tester.pumpWidget(
      wrap(offerings: offerings, conversations: conversations),
    );
    await tester.pump();

    await tester.tap(find.text('Chatear'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(conversations.fetchAllCalls, 1);
    expect(conversations.startCalls, 0);
    expect(find.byType(BuyerChat), findsOneWidget);
  });

  testWidgets('Chatear inicia la conversación con vendedor y oferta', (
    WidgetTester tester,
  ) async {
    final offerings = FakeOfferingRepository();
    final conversations = FakeConversationRepository();

    await tester.pumpWidget(
      wrap(offerings: offerings, conversations: conversations),
    );
    await tester.pump();

    await tester.tap(find.text('Chatear'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(conversations.fetchAllCalls, 1);
    expect(conversations.startCalls, 1);
    expect(conversations.lastFarmerId, 'farmer-1');
    expect(conversations.lastOfferingId, 'offering-1');
    expect(find.byType(BuyerChat), findsOneWidget);
  });

  testWidgets('Chatear falla y muestra el mensaje de error', (
    WidgetTester tester,
  ) async {
    final offerings = FakeOfferingRepository();
    final conversations = FakeConversationRepository()
      ..startError = Exception('boom');

    await tester.pumpWidget(
      wrap(offerings: offerings, conversations: conversations),
    );
    await tester.pump();

    await tester.tap(find.text('Chatear'));
    await tester.pump();

    expect(conversations.startCalls, 1);
    expect(find.byType(BuyerChat), findsNothing);
    expect(find.text('No se pudo iniciar la conversación'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  });
}
