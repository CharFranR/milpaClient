import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/models/auth_models.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/features/buyer/chat.dart';
import 'package:flutter_application_1/features/buyer/conversation_models.dart';
import 'package:flutter_application_1/features/buyer/match_models.dart';
import 'package:flutter_application_1/features/buyer/match_repository.dart';
import 'package:flutter_application_1/features/buyer/supply_request_models.dart';
import 'package:flutter_application_1/features/buyer/transaction_page.dart';
import 'package:flutter_application_1/features/buyer/transaction_repository.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_conversation_repository.dart';
import '../../helpers/fake_offering_repository.dart';
import '../../helpers/fake_user_repository.dart';

const User testUser = User(
  id: 'user-1',
  email: 'oscar@milpa.com',
  firstName: 'Oscar',
  lastName: 'Reyes',
  phoneNumber: '+505 8888 1234',
  role: 2,
);

class FakeTransactionRepository extends TransactionRepository {
  FakeTransactionRepository({Transaction? transaction})
    : transaction = transaction ?? buildTransaction(),
      super(apiClient: ApiClient(), tokenStore: TokenStore());

  Transaction transaction;
  Transaction? afterDelivery;
  List<Transaction> requestTransactions = <Transaction>[];
  Set<String> authoredTransactionIds = <String>{};
  Object? fetchError;
  Object? fetchByRequestError;
  Object? confirmStartError;
  Object? confirmDeliveryError;
  Object? cancelError;
  Object? rateError;
  Object? reviewsError;
  int fetchCalls = 0;
  int fetchByRequestCalls = 0;
  int confirmStartCalls = 0;
  int confirmDeliveryCalls = 0;
  int cancelCalls = 0;
  int rateCalls = 0;
  int reviewsCalls = 0;
  String? lastConfirmedStartId;
  String? lastConfirmedDeliveryId;
  String? lastCancelledId;
  String? lastCancelReason;
  String? lastRatedTransactionId;
  String? lastRatedTargetId;
  int? lastRating;
  String? lastComment;
  String? lastReviewsUserId;

  @override
  Future<Transaction> fetchByMatch(String matchId) async {
    fetchCalls++;
    if (fetchError != null) throw fetchError!;
    return transaction;
  }

  @override
  Future<List<Transaction>> fetchByRequest(String requestId) async {
    fetchByRequestCalls++;
    if (fetchByRequestError != null) throw fetchByRequestError!;
    return List<Transaction>.of(requestTransactions);
  }

  @override
  Future<void> confirmStart(String transactionId) async {
    confirmStartCalls++;
    lastConfirmedStartId = transactionId;
    if (confirmStartError != null) throw confirmStartError!;
  }

  @override
  Future<void> confirmDelivery(String transactionId) async {
    confirmDeliveryCalls++;
    lastConfirmedDeliveryId = transactionId;
    if (confirmDeliveryError != null) throw confirmDeliveryError!;
    final Transaction? next = afterDelivery;
    if (next != null) transaction = next;
  }

  @override
  Future<void> cancel(String transactionId, String reason) async {
    cancelCalls++;
    lastCancelledId = transactionId;
    lastCancelReason = reason;
    if (cancelError != null) throw cancelError!;
  }

  @override
  Future<void> rate({
    required String transactionId,
    required String targetId,
    required int rating,
    required String comment,
  }) async {
    rateCalls++;
    lastRatedTransactionId = transactionId;
    lastRatedTargetId = targetId;
    lastRating = rating;
    lastComment = comment;
    if (rateError != null) throw rateError!;
  }

  @override
  Future<Set<String>> fetchAuthoredReviewTransactionIds(String userId) async {
    reviewsCalls++;
    lastReviewsUserId = userId;
    if (reviewsError != null) throw reviewsError!;
    return Set<String>.of(authoredTransactionIds);
  }
}

class FakeMatchRepository extends MatchRepository {
  FakeMatchRepository({Match? match, MatchOffer? offer})
    : match = match ?? buildMatch(),
      offer = offer ?? buildOffer(),
      super(apiClient: ApiClient(), tokenStore: TokenStore());

  Match match;
  MatchOffer offer;
  Object? matchError;
  Object? offerError;
  int matchCalls = 0;
  int offerCalls = 0;
  String? lastMatchId;
  String? lastOfferId;

  @override
  Future<Match> fetchMatch(String matchId) async {
    matchCalls++;
    lastMatchId = matchId;
    if (matchError != null) throw matchError!;
    return match;
  }

  @override
  Future<MatchOffer> fetchSupplyOffer(String offerId) async {
    offerCalls++;
    lastOfferId = offerId;
    if (offerError != null) throw offerError!;
    return offer;
  }

  @override
  Future<List<Match>> fetchMatches(String requestId) async => <Match>[match];
}

Match buildMatch({String id = 'match-1', String supplyOffer = 'offer-1'}) =>
    Match(
      id: id,
      supplyOffer: supplyOffer,
      supplyRequest: 'request-1',
      status: MatchStatus.active,
      matchedAmount: 500,
      amountUnit: MeasureUnit.kilogram,
      createdAt: '2026-10-04T07:42:02Z',
      updatedAt: '2026-10-04T07:42:02Z',
    );

MatchOffer buildOffer({String supplierId = 'supplier-1'}) => MatchOffer(
  id: 'offer-1',
  supplierId: supplierId,
  supplyRequest: 'request-1',
  totalAmount: 500,
  amountUnit: MeasureUnit.kilogram,
  pricePerUnit: 12.5,
  comments: '',
  proposedDeliveryDay: null,
  deliveryAvailable: true,
  status: OfferStatus.matched,
  createdAt: '2026-10-04T07:42:02Z',
  updatedAt: '2026-10-04T07:42:02Z',
);

Transaction buildTransaction({
  String id = 'tx-1',
  TransactionStatus status = TransactionStatus.matched,
  String? buyerStart,
  String? supplierStart,
  String? buyerDelivery,
  String? supplierDelivery,
  String cancelReason = '',
}) => Transaction(
  id: id,
  matchId: 'match-1',
  status: status,
  buyerStartConfirmedAt: buyerStart,
  supplierStartConfirmedAt: supplierStart,
  buyerDeliveryConfirmedAt: buyerDelivery,
  supplierDeliveryConfirmedAt: supplierDelivery,
  cancelReason: cancelReason,
  createdAt: '2026-10-04T07:42:02Z',
  updatedAt: '2026-10-05T10:00:00Z',
);

Widget wrap({
  required FakeTransactionRepository transactions,
  FakeMatchRepository? matches,
  FakeConversationRepository? conversations,
  FakeOfferingRepository? offerings,
}) => SessionScope(
  controller: SessionController(
    authRepository: FakeAuthRepository(),
    userRepository: FakeUserRepository(current: testUser),
  ),
  child: MaterialApp(
    home: TransactionPage(
      matchId: 'match-1',
      repository: transactions,
      matchRepository: matches ?? FakeMatchRepository(),
      conversationRepository: conversations ?? FakeConversationRepository(),
      offeringRepository: offerings ?? FakeOfferingRepository(),
    ),
  ),
);

Future<void> loadPage(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

String rowText(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey<String>(key))).data!;

bool isEnabled(WidgetTester tester, String label) {
  final Finder finder = find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate(
      (Widget widget) => widget is ButtonStyleButton,
    ),
  );
  return tester.widget<ButtonStyleButton>(finder.first).onPressed != null;
}

void main() {
  testWidgets('muestra estado, agricultor, monto y checklist', (
    WidgetTester tester,
  ) async {
    final FakeTransactionRepository repository = FakeTransactionRepository(
      transaction: buildTransaction(buyerStart: '2026-10-05T10:00:00Z'),
    );

    await tester.pumpWidget(wrap(transactions: repository));
    await loadPage(tester);

    expect(find.text('Acordada'), findsOneWidget);
    expect(find.text('María López'), findsOneWidget);
    expect(find.text('Monto acordado: 500 kg'), findsOneWidget);
    expect(rowText(tester, 'start-buyer'), 'Vos: confirmado el 05/10/2026');
    expect(
      rowText(tester, 'start-supplier'),
      'Falta que el agricultor confirme',
    );
    expect(rowText(tester, 'delivery-buyer'), 'Vos: falta confirmar la entrega');
    expect(
      rowText(tester, 'delivery-supplier'),
      'Falta que el agricultor confirme la entrega',
    );
    expect(repository.fetchCalls, 1);
    expect(repository.reviewsCalls, 1);
    expect(repository.lastReviewsUserId, 'user-1');
  });

  testWidgets('muestra el spinner, luego el error y reintenta', (
    WidgetTester tester,
  ) async {
    final FakeTransactionRepository repository = FakeTransactionRepository()
      ..fetchError = const ApiException(500, 'boom');

    await tester.pumpWidget(wrap(transactions: repository));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await loadPage(tester);

    expect(find.text('No se pudo cargar la transacción'), findsOneWidget);

    repository.fetchError = null;
    await tester.tap(find.text('Reintentar'));
    await loadPage(tester);

    expect(repository.fetchCalls, 2);
    expect(find.text('Acordada'), findsOneWidget);
  });

  testWidgets('en Acordada habilita inicio y deshabilita entrega', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(transactions: FakeTransactionRepository()));
    await loadPage(tester);

    expect(isEnabled(tester, 'Confirmar inicio'), isTrue);
    expect(isEnabled(tester, 'Confirmar entrega'), isFalse);
  });

  testWidgets('en Acordada con mi inicio confirmado deshabilita inicio', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        transactions: FakeTransactionRepository(
          transaction: buildTransaction(buyerStart: '2026-10-05T10:00:00Z'),
        ),
      ),
    );
    await loadPage(tester);

    expect(isEnabled(tester, 'Confirmar inicio'), isFalse);
    expect(isEnabled(tester, 'Confirmar entrega'), isFalse);
  });

  testWidgets('en En proceso habilita entrega y deshabilita inicio', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        transactions: FakeTransactionRepository(
          transaction: buildTransaction(
            status: TransactionStatus.inProgress,
            buyerStart: '2026-10-05T10:00:00Z',
            supplierStart: '2026-10-05T11:00:00Z',
          ),
        ),
      ),
    );
    await loadPage(tester);

    expect(isEnabled(tester, 'Confirmar inicio'), isFalse);
    expect(isEnabled(tester, 'Confirmar entrega'), isTrue);
  });

  testWidgets('en En proceso con mi entrega confirmada deshabilita entrega', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        transactions: FakeTransactionRepository(
          transaction: buildTransaction(
            status: TransactionStatus.inProgress,
            buyerDelivery: '2026-10-06T10:00:00Z',
          ),
        ),
      ),
    );
    await loadPage(tester);

    expect(isEnabled(tester, 'Confirmar entrega'), isFalse);
  });

  testWidgets('en Completada deshabilita confirmaciones y ofrece calificar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        transactions: FakeTransactionRepository(
          transaction: buildTransaction(status: TransactionStatus.completed),
        ),
      ),
    );
    await loadPage(tester);

    expect(isEnabled(tester, 'Confirmar inicio'), isFalse);
    expect(isEnabled(tester, 'Confirmar entrega'), isFalse);
    expect(find.text('Calificar'), findsOneWidget);
  });

  testWidgets('en Cancelada no hay cancelar y muestra el motivo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        transactions: FakeTransactionRepository(
          transaction: buildTransaction(
            status: TransactionStatus.cancelled,
            cancelReason: 'Sin stock',
          ),
        ),
      ),
    );
    await loadPage(tester);

    expect(isEnabled(tester, 'Confirmar inicio'), isFalse);
    expect(isEnabled(tester, 'Confirmar entrega'), isFalse);
    expect(find.text('Cancelar'), findsNothing);
    expect(find.text('Motivo: Sin stock'), findsOneWidget);
  });

  testWidgets('Confirmar inicio llama al repositorio una vez y recarga', (
    WidgetTester tester,
  ) async {
    final FakeTransactionRepository repository = FakeTransactionRepository();

    await tester.pumpWidget(wrap(transactions: repository));
    await loadPage(tester);
    await tester.tap(find.text('Confirmar inicio'));
    await loadPage(tester);

    expect(repository.confirmStartCalls, 1);
    expect(repository.lastConfirmedStartId, 'tx-1');
    expect(repository.fetchCalls, 2);
    expect(find.text('Inicio confirmado'), findsOneWidget);
  });

  testWidgets('Confirmar entrega refresca y muestra Completada', (
    WidgetTester tester,
  ) async {
    final FakeTransactionRepository repository = FakeTransactionRepository(
      transaction: buildTransaction(
        status: TransactionStatus.inProgress,
        buyerStart: '2026-10-05T10:00:00Z',
        supplierStart: '2026-10-05T11:00:00Z',
      ),
    )..afterDelivery = buildTransaction(
      status: TransactionStatus.completed,
      buyerStart: '2026-10-05T10:00:00Z',
      supplierStart: '2026-10-05T11:00:00Z',
      buyerDelivery: '2026-10-06T10:00:00Z',
      supplierDelivery: '2026-10-06T11:00:00Z',
    );

    await tester.pumpWidget(wrap(transactions: repository));
    await loadPage(tester);
    expect(find.text('En proceso'), findsOneWidget);

    await tester.tap(find.text('Confirmar entrega'));
    await loadPage(tester);

    expect(repository.confirmDeliveryCalls, 1);
    expect(repository.lastConfirmedDeliveryId, 'tx-1');
    expect(find.text('Completada'), findsOneWidget);
  });

  testWidgets('el diálogo de cancelación rechaza un motivo en blanco', (
    WidgetTester tester,
  ) async {
    final FakeTransactionRepository repository = FakeTransactionRepository();

    await tester.pumpWidget(wrap(transactions: repository));
    await loadPage(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Cancelar la transacción?'), findsOneWidget);

    await tester.tap(find.text('Cancelar transacción'));
    await tester.pump();

    expect(repository.cancelCalls, 0);
    expect(find.text('Ingresá un motivo'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('cancel-reason')),
      'Sin stock',
    );
    await tester.tap(find.text('Cancelar transacción'));
    await tester.pumpAndSettle();

    expect(repository.cancelCalls, 1);
    expect(repository.lastCancelledId, 'tx-1');
    expect(repository.lastCancelReason, 'Sin stock');
  });

  testWidgets('Calificar publica el target del agricultor', (
    WidgetTester tester,
  ) async {
    final FakeTransactionRepository repository = FakeTransactionRepository(
      transaction: buildTransaction(status: TransactionStatus.completed),
    );

    await tester.pumpWidget(wrap(transactions: repository));
    await loadPage(tester);
    await tester.ensureVisible(find.text('Calificar'));
    await tester.tap(find.text('Calificar'));
    await tester.pumpAndSettle();

    expect(find.text('Calificar al agricultor'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('rate-star-5')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey<String>('rate-comment')),
      'Muy buena',
    );
    await tester.tap(find.text('Enviar calificación'));
    await tester.pumpAndSettle();

    expect(repository.rateCalls, 1);
    expect(repository.lastRatedTransactionId, 'tx-1');
    expect(repository.lastRatedTargetId, 'supplier-1');
    expect(repository.lastRating, 5);
    expect(repository.lastComment, 'Muy buena');
  });

  testWidgets('muestra el estado ya calificado', (WidgetTester tester) async {
    final FakeTransactionRepository repository = FakeTransactionRepository(
      transaction: buildTransaction(status: TransactionStatus.completed),
    )..authoredTransactionIds = <String>{'tx-1'};

    await tester.pumpWidget(wrap(transactions: repository));
    await loadPage(tester);

    expect(find.text('Ya calificaste esta transacción'), findsOneWidget);
    expect(find.text('Calificar'), findsNothing);
  });

  testWidgets('Abrir chat abre la conversación del match', (
    WidgetTester tester,
  ) async {
    final FakeConversationRepository conversations = FakeConversationRepository()
      ..conversations = <Conversation>[
        const Conversation(
          id: 'conversation-9',
          farmerId: 'farmer-1',
          buyerId: 'buyer-1',
          offeringId: '',
          matchId: 'match-1',
          visibility: true,
        ),
      ];

    await tester.pumpWidget(
      wrap(
        transactions: FakeTransactionRepository(),
        conversations: conversations,
      ),
    );
    await loadPage(tester);

    await tester.ensureVisible(find.text('Abrir chat'));
    await tester.tap(find.text('Abrir chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(BuyerChat), findsOneWidget);
  });

  testWidgets('sin conversación desactiva el chat con un texto', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(transactions: FakeTransactionRepository()));
    await loadPage(tester);

    expect(find.text('El chat todavía no está disponible'), findsOneWidget);
    expect(isEnabled(tester, 'Abrir chat'), isFalse);
  });
}
