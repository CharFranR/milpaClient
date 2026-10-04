import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/match_models.dart';
import 'package:flutter_application_1/features/buyer/match_repository.dart';
import 'package:flutter_application_1/features/buyer/request_offers.dart';
import 'package:flutter_application_1/features/buyer/supply_request_models.dart';

class FakeMatchRepository extends MatchRepository {
  FakeMatchRepository({List<PrioritizedOffer>? offers})
    : offers = List<PrioritizedOffer>.of(offers ?? <PrioritizedOffer>[]),
      super(apiClient: ApiClient(), tokenStore: TokenStore());

  final List<PrioritizedOffer> offers;
  Object? fetchError;
  Object? likeError;
  Object? passError;
  int fetchCalls = 0;
  int likeCalls = 0;
  int passCalls = 0;
  String? lastLikedId;
  String? lastPassedId;

  @override
  Future<List<PrioritizedOffer>> fetchPrioritized(String requestId) async {
    fetchCalls++;
    if (fetchError != null) throw fetchError!;
    return List<PrioritizedOffer>.of(offers);
  }

  @override
  Future<MatchResult> like(String offerId) async {
    likeCalls++;
    lastLikedId = offerId;
    if (likeError != null) throw likeError!;
    offers.removeWhere((PrioritizedOffer offer) => offer.offer.id == offerId);
    return const MatchResult(matchId: 'match-1', transactionId: 'tx-1');
  }

  @override
  Future<void> pass(String offerId) async {
    passCalls++;
    lastPassedId = offerId;
    if (passError != null) throw passError!;
    offers.removeWhere((PrioritizedOffer offer) => offer.offer.id == offerId);
  }
}

SupplyRequest buildRequest() => const SupplyRequest(
  id: 'request-1',
  buyerId: 'buyer-1',
  productName: 'Café pergamino',
  description: 'Compra de temporada',
  totalAmount: 800,
  actualAmount: 300,
  amountUnit: MeasureUnit.kilogram,
  numberOfUnits: 100,
  amountPerUnit: 8,
  unitOfMeasure: MeasureUnit.kilogram,
  department: 'Managua',
  municipality: 'Managua',
  addressLine: 'Bodega 12',
  latitude: 12.136,
  longitude: -86.251,
  multipleProviders: true,
  minAmountPerProvider: 100,
  status: SupplyRequestStatus.open,
);

PrioritizedOffer buildPrioritized({
  String id = 'offer-1',
  double? distanceKm = 12.5,
  double availableQuantity = 120,
  double pricePerUnit = 12.5,
  String? proposedDeliveryDay = '2026-10-20T00:00:00Z',
  bool deliveryAvailable = true,
}) => PrioritizedOffer(
  offer: MatchOffer(
    id: id,
    supplierId: 'supplier-1',
    supplyRequest: 'request-1',
    totalAmount: 500,
    amountUnit: MeasureUnit.kilogram,
    pricePerUnit: pricePerUnit,
    comments: 'Entrega temprano en la bodega',
    proposedDeliveryDay: proposedDeliveryDay,
    deliveryAvailable: deliveryAvailable,
    status: OfferStatus.active,
    createdAt: '2026-10-04T07:42:02Z',
    updatedAt: '2026-10-04T07:42:02Z',
  ),
  score: 0.55,
  availableQuantity: availableQuantity,
  distanceKm: distanceKm,
  contributions: const <ScoreContribution>[
    ScoreContribution(
      factor: 'distance',
      weight: 0.3,
      score: 0.66,
      weightedScore: 0.2,
    ),
    ScoreContribution(
      factor: 'price',
      weight: 0.15,
      score: 1,
      weightedScore: 0.15,
    ),
  ],
);

Widget wrap(FakeMatchRepository repository) => MaterialApp(
  home: RequestOffersPage(request: buildRequest(), repository: repository),
);

Future<void> loadPage(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('shows loading and then the prioritized offers', (
    WidgetTester tester,
  ) async {
    final FakeMatchRepository repository = FakeMatchRepository(
      offers: <PrioritizedOffer>[buildPrioritized()],
    );

    await tester.pumpWidget(wrap(repository));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await loadPage(tester);

    expect(repository.fetchCalls, 1);
    expect(find.textContaining('C\$ 12,50'), findsOneWidget);
    expect(find.text('Cantidad ofrecida: 500 kg'), findsOneWidget);
    expect(find.text('Disponible: 120 kg'), findsOneWidget);
    expect(find.text('Entrega: Sí'), findsOneWidget);
    expect(find.text('Distancia: 12.5 km'), findsOneWidget);
    expect(find.text('Aceptar'), findsOneWidget);
    expect(find.text('Descartar'), findsOneWidget);
  });

  testWidgets('shows the empty state copy', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(FakeMatchRepository()));
    await loadPage(tester);

    expect(find.text('Todavía no hay ofertas para esta solicitud'), findsOneWidget);
    expect(
      find.text(
        'Cuando un agricultor ofrezca, la vas a ver acá para aceptarla o descartarla.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('fetch failure can be retried', (WidgetTester tester) async {
    final FakeMatchRepository repository = FakeMatchRepository(
      offers: <PrioritizedOffer>[buildPrioritized()],
    )..fetchError = const ApiException(500, 'boom');

    await tester.pumpWidget(wrap(repository));
    await loadPage(tester);
    expect(find.text('No se pudieron cargar las ofertas'), findsOneWidget);

    repository.fetchError = null;
    await tester.tap(find.text('Reintentar'));
    await loadPage(tester);

    expect(repository.fetchCalls, 2);
    expect(find.text('Aceptar'), findsOneWidget);
  });

  testWidgets('confirming calls like once with the right id and refreshes', (
    WidgetTester tester,
  ) async {
    final FakeMatchRepository repository = FakeMatchRepository(
      offers: <PrioritizedOffer>[buildPrioritized(id: 'offer-9')],
    );

    await tester.pumpWidget(wrap(repository));
    await loadPage(tester);
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    expect(repository.likeCalls, 1);
    expect(repository.lastLikedId, 'offer-9');
    expect(repository.fetchCalls, 2);
    expect(find.text('Oferta aceptada'), findsOneWidget);
  });

  testWidgets('discarding calls pass with the right id', (
    WidgetTester tester,
  ) async {
    final FakeMatchRepository repository = FakeMatchRepository(
      offers: <PrioritizedOffer>[buildPrioritized(id: 'offer-3')],
    );

    await tester.pumpWidget(wrap(repository));
    await loadPage(tester);
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();

    expect(repository.passCalls, 1);
    expect(repository.lastPassedId, 'offer-3');
    expect(repository.likeCalls, 0);
    expect(find.text('Oferta descartada'), findsOneWidget);
  });

  testWidgets('swiping right accepts the offer', (WidgetTester tester) async {
    final FakeMatchRepository repository = FakeMatchRepository(
      offers: <PrioritizedOffer>[buildPrioritized(id: 'swipe-right')],
    );

    await tester.pumpWidget(wrap(repository));
    await loadPage(tester);
    await tester.drag(
      find.byKey(const ValueKey<String>('offer-swipe-right')),
      const Offset(500, 0),
    );
    await tester.pumpAndSettle();

    expect(repository.likeCalls, 1);
    expect(repository.lastLikedId, 'swipe-right');
  });

  testWidgets('swiping left discards the offer', (WidgetTester tester) async {
    final FakeMatchRepository repository = FakeMatchRepository(
      offers: <PrioritizedOffer>[buildPrioritized(id: 'swipe-left')],
    );

    await tester.pumpWidget(wrap(repository));
    await loadPage(tester);
    await tester.drag(
      find.byKey(const ValueKey<String>('offer-swipe-left')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(repository.passCalls, 1);
    expect(repository.lastPassedId, 'swipe-left');
    expect(repository.likeCalls, 0);
  });

  testWidgets('an offer without distance_km omits the distance row', (
    WidgetTester tester,
  ) async {
    final FakeMatchRepository repository = FakeMatchRepository(
      offers: <PrioritizedOffer>[buildPrioritized(distanceKm: null)],
    );

    await tester.pumpWidget(wrap(repository));
    await loadPage(tester);

    expect(find.textContaining('km'), findsNothing);
    expect(find.text('Disponible: 120 kg'), findsOneWidget);
  });

  testWidgets('a 409 on like shows the server message and refreshes', (
    WidgetTester tester,
  ) async {
    final FakeMatchRepository repository = FakeMatchRepository(
      offers: <PrioritizedOffer>[buildPrioritized(id: 'offer-1')],
    )..likeError = const ApiException(409, 'La oferta ya no está disponible');

    await tester.pumpWidget(wrap(repository));
    await loadPage(tester);
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    expect(repository.likeCalls, 1);
    expect(repository.fetchCalls, 2);
    expect(find.text('La oferta ya no está disponible'), findsOneWidget);
  });

  testWidgets('the breakdown expands with friendly Spanish labels', (
    WidgetTester tester,
  ) async {
    final FakeMatchRepository repository = FakeMatchRepository(
      offers: <PrioritizedOffer>[buildPrioritized()],
    );

    await tester.pumpWidget(wrap(repository));
    await loadPage(tester);
    await tester.tap(find.text('Desglose del puntaje'));
    await tester.pumpAndSettle();

    expect(find.text('Distancia'), findsOneWidget);
    expect(find.text('Precio'), findsOneWidget);
    expect(find.text('0.20'), findsOneWidget);
    expect(find.text('0.15'), findsOneWidget);
  });
}
