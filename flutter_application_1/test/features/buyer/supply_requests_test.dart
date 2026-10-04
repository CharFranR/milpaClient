import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/models/auth_models.dart';
import 'package:flutter_application_1/features/buyer/supply_request_form.dart';
import 'package:flutter_application_1/features/buyer/supply_request_models.dart';
import 'package:flutter_application_1/features/buyer/supply_requests.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/ui/labeled_field.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_supply_request_repository.dart';
import '../../helpers/fake_user_repository.dart';

Widget wrap(FakeSupplyRequestRepository repository) {
  return MaterialApp(home: SupplyRequestsPage(repository: repository));
}

Finder fieldWithLabel(String label) {
  return find.descendant(
    of: find.ancestor(
      of: find.text(label),
      matching: find.byType(LabeledField),
    ),
    matching: find.byType(TextFormField),
  );
}

Future<void> loadPage(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('shows loading and then the three seeded requests', (
    WidgetTester tester,
  ) async {
    final FakeSupplyRequestRepository repository = FakeSupplyRequestRepository(
      requests: <SupplyRequest>[
        buildSupplyRequest(
          id: 'open',
          productName: 'Café',
          status: SupplyRequestStatus.open,
        ),
        buildSupplyRequest(
          id: 'cancelled',
          productName: 'Maíz',
          status: SupplyRequestStatus.cancelled,
        ),
        buildSupplyRequest(
          id: 'completed',
          productName: 'Frijol',
          status: SupplyRequestStatus.completed,
        ),
      ],
    );

    await tester.pumpWidget(wrap(repository));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await loadPage(tester);

    expect(find.text('Café'), findsOneWidget);
    expect(find.text('Maíz'), findsOneWidget);
    expect(find.text('Frijol'), findsOneWidget);
    expect(find.text('Abierta'), findsOneWidget);
    expect(find.text('Cancelada'), findsOneWidget);
    expect(find.text('Completada'), findsOneWidget);
  });

  testWidgets('shows the empty state copy', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(FakeSupplyRequestRepository()));
    await loadPage(tester);

    expect(find.text('Todavía no tenés solicitudes'), findsOneWidget);
    expect(
      find.text(
        'Creá tu primera solicitud para empezar a comprar al por mayor.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('fetch failure can be retried', (WidgetTester tester) async {
    final FakeSupplyRequestRepository repository = FakeSupplyRequestRepository(
      requests: <SupplyRequest>[buildSupplyRequest()],
    )..fetchError = const ApiException(500, 'boom');

    await tester.pumpWidget(wrap(repository));
    await loadPage(tester);
    expect(find.text('No se pudieron cargar tus solicitudes'), findsOneWidget);

    repository.fetchError = null;
    await tester.tap(find.text('Reintentar'));
    await loadPage(tester);

    expect(repository.fetchAllCalls, 2);
    expect(find.text('Café pergamino'), findsOneWidget);
  });

  testWidgets('cancelling confirms, reloads, and shows a message', (
    WidgetTester tester,
  ) async {
    final FakeSupplyRequestRepository repository = FakeSupplyRequestRepository(
      requests: <SupplyRequest>[buildSupplyRequest(id: 'cancel-me')],
    );

    await tester.pumpWidget(wrap(repository));
    await loadPage(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Cancelar esta solicitud?'), findsOneWidget);
    await tester.tap(find.text('Cancelar solicitud'));
    await tester.pumpAndSettle();

    expect(repository.cancelCalls, 1);
    expect(repository.lastCancelledId, 'cancel-me');
    expect(repository.fetchAllCalls, 2);
    expect(find.text('Solicitud cancelada'), findsOneWidget);
  });

  testWidgets('dismissing the confirmation does not cancel', (
    WidgetTester tester,
  ) async {
    final FakeSupplyRequestRepository repository = FakeSupplyRequestRepository(
      requests: <SupplyRequest>[buildSupplyRequest()],
    );

    await tester.pumpWidget(wrap(repository));
    await loadPage(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();

    expect(repository.cancelCalls, 0);
  });

  testWidgets('cancel failure shows mapped message and keeps the row', (
    WidgetTester tester,
  ) async {
    final FakeSupplyRequestRepository repository = FakeSupplyRequestRepository(
      requests: <SupplyRequest>[buildSupplyRequest()],
    )..cancelError = const ApiException(403, 'forbidden');

    await tester.pumpWidget(wrap(repository));
    await loadPage(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar solicitud'));
    await tester.pumpAndSettle();

    expect(
      find.text('Solo los compradores mayoristas pueden hacer esto'),
      findsOneWidget,
    );
    expect(find.text('Café pergamino'), findsOneWidget);
    expect(repository.fetchAllCalls, 1);
    expect(repository.cancelCalls, 1);
  });

  testWidgets('cancel failure calls the repository once', (
    WidgetTester tester,
  ) async {
    final FakeSupplyRequestRepository repository = FakeSupplyRequestRepository(
      requests: <SupplyRequest>[
        buildSupplyRequest(id: 'cancel-me', productName: 'Café'),
        buildSupplyRequest(id: 'keep-me', productName: 'Maíz'),
      ],
    )..cancelError = const ApiException(403, 'forbidden');

    await tester.pumpWidget(wrap(repository));
    await loadPage(tester);
    await tester.tap(find.text('Cancelar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar solicitud'));
    await tester.pumpAndSettle();

    expect(repository.cancelCalls, 1);
    expect(
      find.text('Solo los compradores mayoristas pueden hacer esto'),
      findsOneWidget,
    );
    expect(find.text('Café'), findsOneWidget);
    expect(find.text('Maíz'), findsOneWidget);
  });

  testWidgets('non-open requests have no edit or cancel actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        FakeSupplyRequestRepository(
          requests: <SupplyRequest>[
            buildSupplyRequest(status: SupplyRequestStatus.expired),
          ],
        ),
      ),
    );
    await loadPage(tester);

    expect(find.text('Editar'), findsNothing);
    expect(find.text('Cancelar'), findsNothing);
  });

  testWidgets('new request opens the form and returning true reloads', (
    WidgetTester tester,
  ) async {
    final FakeSupplyRequestRepository repository = FakeSupplyRequestRepository(
      requests: <SupplyRequest>[buildSupplyRequest()],
    );

    await tester.pumpWidget(wrap(repository));
    await loadPage(tester);
    await tester.tap(find.text('Nueva solicitud'));
    await tester.pumpAndSettle();
    expect(find.byType(SupplyRequestFormPage), findsOneWidget);

    Navigator.of(tester.element(find.byType(SupplyRequestFormPage))).pop(true);
    await tester.pumpAndSettle();
    expect(repository.fetchAllCalls, 2);
  });

  testWidgets('empty form shows validation messages without creating', (
    WidgetTester tester,
  ) async {
    final FakeSupplyRequestRepository repository =
        FakeSupplyRequestRepository();

    await tester.pumpWidget(
      MaterialApp(home: SupplyRequestFormPage(repository: repository)),
    );
    await tester.ensureVisible(find.text('Publicar solicitud'));
    await tester.tap(find.text('Publicar solicitud'));
    await tester.pump();

    expect(find.text('Ingresa producto'), findsOneWidget);
    expect(find.text('Ingresa cantidad total'), findsOneWidget);
    expect(find.text('Ingresa cantidad de unidades'), findsOneWidget);
    expect(find.text('Ingresa precio por unidad'), findsOneWidget);
    expect(find.text('Ingresa departamento'), findsOneWidget);
    expect(find.text('Ingresa municipio'), findsOneWidget);
    expect(find.text('Ingresa dirección'), findsOneWidget);
    expect(repository.createCalls, 0);
  });

  testWidgets('valid create sends the selected unit and default deadlines', (
    WidgetTester tester,
  ) async {
    final FakeSupplyRequestRepository repository =
        FakeSupplyRequestRepository();

    await tester.pumpWidget(
      MaterialApp(home: SupplyRequestFormPage(repository: repository)),
    );
    await tester.enterText(fieldWithLabel('Producto'), 'Café');
    await tester.enterText(fieldWithLabel('Cantidad total'), '800');
    await tester.enterText(fieldWithLabel('Cantidad de unidades'), '100');
    await tester.enterText(fieldWithLabel('Precio por unidad'), '8,50');
    await tester.enterText(fieldWithLabel('Departamento'), 'Managua');
    await tester.enterText(fieldWithLabel('Municipio'), 'Managua');
    await tester.enterText(fieldWithLabel('Dirección'), 'Bodega 12');
    await tester.ensureVisible(find.text('lb'));
    await tester.tap(find.text('lb'));
    await tester.ensureVisible(find.text('Publicar solicitud'));
    await tester.tap(find.text('Publicar solicitud'));
    await tester.pumpAndSettle();

    final SupplyRequestDraft draft = repository.lastDraft!;
    expect(repository.createCalls, 1);
    expect(draft.amountUnit, MeasureUnit.pound);
    expect(draft.unitOfMeasure, MeasureUnit.pound);
    expect(draft.requestDeadline, isNotNull);
    expect(draft.deliveryDeadline, isNotNull);
    expect(
      draft.deliveryDeadline!.difference(draft.requestDeadline!).inDays,
      30,
    );
    expect(find.byType(SupplyRequestFormPage), findsNothing);
  });

  testWidgets('edit mode is prefilled and updates the request id', (
    WidgetTester tester,
  ) async {
    final SupplyRequest request = buildSupplyRequest(id: 'edit-me');
    final FakeSupplyRequestRepository repository =
        FakeSupplyRequestRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: SupplyRequestFormPage(request: request, repository: repository),
      ),
    );
    expect(find.text('Café pergamino'), findsOneWidget);
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, 1);
    expect(repository.lastUpdatedId, 'edit-me');
    expect(repository.lastDraft!.productName, 'Café pergamino');
  });

  testWidgets('edit failure shows the message and does not pop', (
    WidgetTester tester,
  ) async {
    final SupplyRequest request = buildSupplyRequest(id: 'edit-me');
    final FakeSupplyRequestRepository repository = FakeSupplyRequestRepository()
      ..updateError = const ApiException(409, 'conflict');

    await tester.pumpWidget(
      MaterialApp(
        home: SupplyRequestFormPage(request: request, repository: repository),
      ),
    );
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(
      find.text('La solicitud no se puede modificar en este momento'),
      findsOneWidget,
    );
    expect(repository.updateCalls, 1);
    expect(find.byType(SupplyRequestFormPage), findsOneWidget);
  });

  testWidgets('rejects a request deadline after the delivery deadline', (
    WidgetTester tester,
  ) async {
    final FakeSupplyRequestRepository repository =
        FakeSupplyRequestRepository();

    await tester.pumpWidget(
      MaterialApp(home: SupplyRequestFormPage(repository: repository)),
    );
    await tester.ensureVisible(find.byType(OutlinedButton).at(1));
    await tester.tap(find.byType(OutlinedButton).at(1));
    await tester.pumpAndSettle();
    final DateTime deliveryDeadline = DateUtils.dateOnly(
      DateTime.now(),
    ).add(const Duration(days: 60));
    final DateTime selectedDeliveryDate = DateTime(
      deliveryDeadline.year,
      deliveryDeadline.month - 1,
      1,
    );
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      tester.element(find.byType(DatePickerDialog)),
    );
    await tester.tap(
      find.bySemanticsLabel(
        RegExp(
          '^1, ${RegExp.escape(localizations.formatFullDate(selectedDeliveryDate))}',
        ),
      ),
    );
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
    await tester.enterText(fieldWithLabel('Producto'), 'Café');
    await tester.enterText(fieldWithLabel('Cantidad total'), '800');
    await tester.enterText(fieldWithLabel('Cantidad de unidades'), '100');
    await tester.enterText(fieldWithLabel('Precio por unidad'), '8');
    await tester.enterText(fieldWithLabel('Departamento'), 'Managua');
    await tester.enterText(fieldWithLabel('Municipio'), 'Managua');
    await tester.enterText(fieldWithLabel('Dirección'), 'Bodega 12');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Publicar solicitud'));
    await tester.tap(find.text('Publicar solicitud'));
    await tester.pump();

    expect(
      find.text('La fecha límite no puede ser posterior a la entrega'),
      findsOneWidget,
    );
    expect(repository.createCalls, 0);
  });

  testWidgets('create failure shows the message and does not pop', (
    WidgetTester tester,
  ) async {
    final FakeSupplyRequestRepository repository = FakeSupplyRequestRepository()
      ..createError = const ApiException(400, 'invalid');

    await tester.pumpWidget(
      MaterialApp(home: SupplyRequestFormPage(repository: repository)),
    );
    await tester.enterText(fieldWithLabel('Producto'), 'Café');
    await tester.enterText(fieldWithLabel('Cantidad total'), '800');
    await tester.enterText(fieldWithLabel('Cantidad de unidades'), '100');
    await tester.enterText(fieldWithLabel('Precio por unidad'), '8');
    await tester.enterText(fieldWithLabel('Departamento'), 'Managua');
    await tester.enterText(fieldWithLabel('Municipio'), 'Managua');
    await tester.enterText(fieldWithLabel('Dirección'), 'Bodega 12');
    await tester.ensureVisible(find.text('Publicar solicitud'));
    await tester.tap(find.text('Publicar solicitud'));
    await tester.pumpAndSettle();

    expect(find.text('Revisá los datos del formulario'), findsOneWidget);
    expect(find.byType(SupplyRequestFormPage), findsOneWidget);
  });

  test('canPublishSupplyRequests only allows wholesale roles', () {
    expect(canPublishSupplyRequests(3), isTrue);
    expect(canPublishSupplyRequests(4), isTrue);
    expect(canPublishSupplyRequests(1), isFalse);
    expect(canPublishSupplyRequests(2), isFalse);
    expect(canPublishSupplyRequests(5), isFalse);
    expect(canPublishSupplyRequests(6), isFalse);
    expect(canPublishSupplyRequests(null), isFalse);
  });

  testWidgets('BuyerLayout shows the FAB for role 3', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MainApp(
        authRepository: FakeAuthRepository(
          session: (token: 't', userId: 'user-1'),
        ),
        userRepository: FakeUserRepository(
          current: const User(
            id: 'user-1',
            email: 'buyer@example.com',
            firstName: 'Buyer',
            lastName: 'Three',
            phoneNumber: '123',
            role: 3,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('BuyerLayout hides the FAB for role 2', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MainApp(
        authRepository: FakeAuthRepository(
          session: (token: 't', userId: 'user-1'),
        ),
        userRepository: FakeUserRepository(current: defaultFakeUser),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
