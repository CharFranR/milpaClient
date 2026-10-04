import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/location_reporter.dart';
import 'package:flutter_application_1/features/auth/register_models.dart';
import 'package:flutter_application_1/features/auth/register_view.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/ui/labeled_field.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/fake_location_reporter.dart';
import 'helpers/fake_user_repository.dart';

Finder fieldWithLabel(String label) {
  return find.descendant(
    of: find.ancestor(
      of: find.text(label),
      matching: find.byType(LabeledField),
    ),
    matching: find.byType(TextFormField),
  );
}

Finder get submitButton => find.widgetWithText(TextButton, 'Crear cuenta');

bool submitEnabled(WidgetTester tester) =>
    tester.widget<TextButton>(submitButton).onPressed != null;

Future<void> pumpRegister(
  WidgetTester tester,
  FakeAuthRepository fake, {
  LocationReporter? locationReporter,
}) async {
  await tester.pumpWidget(
    SessionScope(
      controller: SessionController(
        authRepository: fake,
        userRepository: FakeUserRepository(),
      ),
      child: MaterialApp(
        home: RegisterView(
          locationReporter: locationReporter ?? FakeLocationReporter(),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> tapSubmit(WidgetTester tester) async {
  await tester.ensureVisible(submitButton);
  await tester.tap(submitButton);
  await tester.pump();
}

Future<void> fillForm(WidgetTester tester) async {
  await tester.enterText(fieldWithLabel('Nombre'), '  Juan  ');
  await tester.enterText(fieldWithLabel('Apellido'), 'Pérez');
  await tester.enterText(
    fieldWithLabel('Correo electrónico'),
    'juan@milpa.com',
  );
  await tester.enterText(fieldWithLabel('Teléfono'), '8888 1234');
  await tester.enterText(fieldWithLabel('Contraseña'), 'secreta123');
  await tester.enterText(fieldWithLabel('Confirmar contraseña'), 'secreta123');
  await tester.pump();
}

Future<void> fillHappyPath(
  WidgetTester tester, {
  String role = 'Comprador',
}) async {
  await tester.tap(find.text(role));
  await tester.pump();
  await fillForm(tester);
}

void main() {
  test('los roles usan los ids del contrato del servidor', () {
    expect(RegisterRole.agricultor.roleId, 1);
    expect(RegisterRole.compradorMinorista.roleId, 2);
    expect(RegisterRole.compradorMayoristaDetallista.roleId, 3);
    expect(RegisterRole.compradorMayoristaCorporativo.roleId, 4);
  });

  group('RegisterView', () {
    testWidgets('el botón está deshabilitado hasta elegir un rol', (
      WidgetTester tester,
    ) async {
      final fake = FakeAuthRepository();
      await pumpRegister(tester, fake);

      expect(submitEnabled(tester), isFalse);

      await tester.tap(find.text('Comprador'));
      await tester.pump();
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets('Comprador define el rol 2 y muestra los tipos de comprador', (
      WidgetTester tester,
    ) async {
      final fake = FakeAuthRepository();
      await pumpRegister(tester, fake);

      expect(find.text('Tipo de comprador'), findsNothing);

      await tester.tap(find.text('Comprador'));
      await tester.pump();

      expect(find.text('Tipo de comprador'), findsOneWidget);
      expect(find.text('Minorista'), findsOneWidget);
      expect(find.text('Detallista'), findsOneWidget);
      expect(find.text('Corporativo'), findsOneWidget);

      await fillForm(tester);
      await tapSubmit(tester);

      expect(fake.lastRegisteredRole, 2);
    });

    testWidgets('Productor define el rol 1 y oculta los tipos de comprador', (
      WidgetTester tester,
    ) async {
      final fake = FakeAuthRepository();
      await pumpRegister(tester, fake);

      await tester.tap(find.text('Comprador'));
      await tester.pump();
      expect(find.text('Tipo de comprador'), findsOneWidget);

      await tester.tap(find.text('Productor'));
      await tester.pump();
      expect(find.text('Tipo de comprador'), findsNothing);

      await fillForm(tester);
      await tapSubmit(tester);

      expect(fake.lastRegisteredRole, 1);
    });

    testWidgets('tocar Corporativo define el rol 4', (
      WidgetTester tester,
    ) async {
      final fake = FakeAuthRepository();
      await pumpRegister(tester, fake);

      await tester.tap(find.text('Comprador'));
      await tester.pump();
      await tester.tap(find.text('Corporativo'));
      await tester.pump();

      await fillForm(tester);
      await tapSubmit(tester);

      expect(fake.lastRegisteredRole, 4);
    });

    testWidgets('tocar Detallista define el rol 3', (
      WidgetTester tester,
    ) async {
      final fake = FakeAuthRepository();
      await pumpRegister(tester, fake);

      await tester.tap(find.text('Comprador'));
      await tester.pump();
      await tester.tap(find.text('Detallista'));
      await tester.pump();

      await fillForm(tester);
      await tapSubmit(tester);

      expect(fake.lastRegisteredRole, 3);
    });

    testWidgets('el envío exitoso registra y luego inicia sesión', (
      WidgetTester tester,
    ) async {
      final fake = FakeAuthRepository();
      await pumpRegister(tester, fake);

      await fillHappyPath(tester);
      await tapSubmit(tester);

      expect(fake.registerCalls, 1);
      expect(fake.loginCalls, 1);
      expect(fake.lastRegisteredRole, 2);
      expect(fake.lastRegisteredEmail, 'juan@milpa.com');
    });

    testWidgets('el registro envía la dirección escrita', (
      WidgetTester tester,
    ) async {
      final fake = FakeAuthRepository();
      await pumpRegister(tester, fake);

      await fillHappyPath(tester);
      await tester.enterText(
        fieldWithLabel('Dirección'),
        'Barrio San Juan, casa 12',
      );
      await tapSubmit(tester);

      expect(fake.lastRegisteredAddress, 'Barrio San Juan, casa 12');
    });

    testWidgets('sin compartir la ubicación no se envían coordenadas', (
      WidgetTester tester,
    ) async {
      final fake = FakeAuthRepository();
      final reporter = FakeLocationReporter(
        result: const Coordinates(latitude: 12.1364, longitude: -86.2514),
      );
      await pumpRegister(tester, fake, locationReporter: reporter);

      await fillHappyPath(tester);
      await tapSubmit(tester);

      expect(reporter.calls, 0);
      expect(fake.lastRegisteredLatitude, isNull);
      expect(fake.lastRegisteredLongitude, isNull);
    });

    testWidgets('compartir la ubicación envía las coordenadas capturadas', (
      WidgetTester tester,
    ) async {
      final fake = FakeAuthRepository();
      final reporter = FakeLocationReporter(
        result: const Coordinates(latitude: 12.1364, longitude: -86.2514),
      );
      await pumpRegister(tester, fake, locationReporter: reporter);

      await fillHappyPath(tester);
      final Finder sharing = find.text('Compartir mi ubicación');
      await tester.ensureVisible(sharing);
      await tester.tap(sharing);
      await tester.pumpAndSettle();
      await tapSubmit(tester);

      expect(reporter.calls, 1);
      expect(fake.lastRegisteredLatitude, 12.1364);
      expect(fake.lastRegisteredLongitude, -86.2514);
    });

    testWidgets('un 409 avisa que el correo ya está registrado', (
      WidgetTester tester,
    ) async {
      final fake = FakeAuthRepository(
        registerError: const ApiException(409, 'conflict'),
      );
      await pumpRegister(tester, fake);

      await fillHappyPath(tester);
      await tapSubmit(tester);

      expect(fake.registerCalls, 1);
      expect(fake.loginCalls, 0);
      expect(find.text('Ese correo ya está registrado'), findsOneWidget);
      expect(find.byType(RegisterView), findsOneWidget);
      expect(submitEnabled(tester), isTrue);

      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('bloquea el envío si el formulario es inválido', (
      WidgetTester tester,
    ) async {
      final fake = FakeAuthRepository();
      await pumpRegister(tester, fake);
      await tester.tap(find.text('Comprador'));
      await tester.pump();
      await tapSubmit(tester);

      expect(fake.registerCalls, 0);
      expect(find.text('Ingresa tu nombre'), findsOneWidget);
      expect(find.text('Ingresa tu correo electrónico'), findsOneWidget);
      expect(find.text('Ingresa tu número de teléfono'), findsOneWidget);
    });

    testWidgets('rechaza contraseña corta, correo inválido y teléfono corto', (
      WidgetTester tester,
    ) async {
      final fake = FakeAuthRepository();
      await pumpRegister(tester, fake);
      await tester.tap(find.text('Comprador'));
      await tester.pump();
      await tester.enterText(fieldWithLabel('Nombre'), 'Juan');
      await tester.enterText(fieldWithLabel('Apellido'), 'Pérez');
      await tester.enterText(
        fieldWithLabel('Correo electrónico'),
        'no-es-mail',
      );
      await tester.enterText(fieldWithLabel('Teléfono'), '123');
      await tester.enterText(fieldWithLabel('Contraseña'), 'corta');
      await tester.enterText(fieldWithLabel('Confirmar contraseña'), 'otra');
      await tester.pump();
      await tapSubmit(tester);

      expect(fake.registerCalls, 0);
      expect(find.text('Ingresa un correo válido'), findsOneWidget);
      expect(
        find.text('Ingresa un teléfono de 8 a 15 dígitos'),
        findsOneWidget,
      );
      expect(
        find.text('La contraseña debe tener al menos 8 caracteres'),
        findsOneWidget,
      );
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });

    testWidgets('un fallo del registro muestra SnackBar y deja reintentar', (
      WidgetTester tester,
    ) async {
      final fake = FakeAuthRepository(registerError: StateError('fallo'));
      await pumpRegister(tester, fake);

      await fillHappyPath(tester);
      await tapSubmit(tester);

      expect(fake.registerCalls, 1);
      expect(fake.loginCalls, 0);
      expect(
        find.text('No se pudo crear la cuenta. Intenta de nuevo.'),
        findsOneWidget,
      );
      expect(submitEnabled(tester), isTrue);

      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('a 1000px de ancho los campos van en dos columnas', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final fake = FakeAuthRepository();
      await pumpRegister(tester, fake);

      final double firstRowY = tester.getTopLeft(fieldWithLabel('Nombre')).dy;
      final double lastRowY = tester.getTopLeft(fieldWithLabel('Apellido')).dy;
      expect(firstRowY, lastRowY);

      tester.view.physicalSize = const Size(400, 1400);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(fieldWithLabel('Apellido')).dy > firstRowY,
        isTrue,
      );
    });
  });
}
