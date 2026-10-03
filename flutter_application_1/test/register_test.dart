import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/features/auth/register_models.dart';
import 'package:flutter_application_1/features/auth/register_repository.dart';
import 'package:flutter_application_1/features/auth/register_view.dart';
import 'package:flutter_application_1/ui/labeled_field.dart';

/// Repository en memoria: captura el request y no espera nada.
class _RecordingRepository implements RegisterRepository {
  _RecordingRepository({this.shouldFail = false});

  final bool shouldFail;
  RegisterUserRequest? received;

  @override
  Future<void> register(RegisterUserRequest request) async {
    received = request;
    if (shouldFail) {
      throw StateError('fallo simulado');
    }
  }
}

/// El label vive fuera del TextFormField, así que se busca el campo como
/// descendiente del LabeledField que contiene ese label.
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

Future<void> tapSubmit(WidgetTester tester) async {
  await tester.ensureVisible(submitButton);
  await tester.tap(submitButton);
  await tester.pump();
}

Future<void> fillHappyPath(
  WidgetTester tester, {
  String role = 'Comprador',
}) async {
  await tester.tap(find.text(role));
  await tester.pump();
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

void main() {
  group('RegisterUserRequest.toJson', () {
    const RegisterUserRequest full = RegisterUserRequest(
      email: 'juan@milpa.com',
      firstName: 'Juan',
      lastName: 'Pérez',
      role: RegisterRole.producer,
      address: 'Barrio Centro',
      department: 'Masaya',
      municipality: 'Masate',
      phoneNumber: '88881234',
      password: 'secreta123',
      confirmPassword: 'secreta123',
    );

    test('manda todos los campos y el role como entero', () {
      expect(full.toJson(), <String, dynamic>{
        'email': 'juan@milpa.com',
        'first_name': 'Juan',
        'last_name': 'Pérez',
        'role': 2,
        'password': 'secreta123',
        'confirm_password': 'secreta123',
        'phone_number': '88881234',
        'address': 'Barrio Centro',
        'department': 'Masaya',
        'municipality': 'Masate',
      });
    });

    test('omite los campos opcionales vacíos y nunca manda coordenadas', () {
      const RegisterUserRequest minimal = RegisterUserRequest(
        email: 'juan@milpa.com',
        firstName: 'Juan',
        lastName: 'Pérez',
        role: RegisterRole.buyer,
        phoneNumber: '88881234',
        password: 'secreta123',
        confirmPassword: 'secreta123',
      );

      expect(minimal.toJson(), <String, dynamic>{
        'email': 'juan@milpa.com',
        'first_name': 'Juan',
        'last_name': 'Pérez',
        'role': 1,
        'password': 'secreta123',
        'confirm_password': 'secreta123',
        'phone_number': '88881234',
      });
      expect(minimal.toJson().containsKey('latitude'), isFalse);
      expect(minimal.toJson().containsKey('longitude'), isFalse);
    });
  });

  group('FakeRegisterRepository', () {
    test(
      'resuelve sin lanzar y lanza cuando se configura para fallar',
      () async {
        await const FakeRegisterRepository(latency: Duration.zero).register(
          const RegisterUserRequest(
            email: 'a@b.co',
            firstName: 'A',
            lastName: 'B',
            role: RegisterRole.buyer,
            phoneNumber: '88881234',
            password: 'secreta123',
            confirmPassword: 'secreta123',
          ),
        );

        expect(
          const FakeRegisterRepository(
            latency: Duration.zero,
            shouldFail: true,
          ).register(
            const RegisterUserRequest(
              email: 'a@b.co',
              firstName: 'A',
              lastName: 'B',
              role: RegisterRole.buyer,
              phoneNumber: '88881234',
              password: 'secreta123',
              confirmPassword: 'secreta123',
            ),
          ),
          throwsStateError,
        );
      },
    );
  });

  group('RegisterView', () {
    late _RecordingRepository repository;

    setUp(() => repository = _RecordingRepository());

    Future<void> pumpRegister(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: RegisterView(repository: repository)),
      );
    }

    testWidgets('el botón está deshabilitado hasta elegir un rol', (
      WidgetTester tester,
    ) async {
      await pumpRegister(tester);

      expect(submitEnabled(tester), isFalse);

      await tester.tap(find.text('Comprador'));
      await tester.pump();
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets('envía role=1 cuando se elige Comprador', (
      WidgetTester tester,
    ) async {
      await pumpRegister(tester);
      await fillHappyPath(tester);
      await tapSubmit(tester);

      expect(repository.received, isNotNull);
      expect(repository.received!.role, RegisterRole.buyer);
      expect(repository.received!.role.roleId, 1);
      // El nombre se envía sin espacios sobrantes.
      expect(repository.received!.firstName, 'Juan');
      // El teléfono se envía solo con dígitos.
      expect(repository.received!.phoneNumber, '88881234');
      expect(
        find.text('¡Cuenta creada! Ya puedes iniciar sesión.'),
        findsOneWidget,
      );
    });

    testWidgets('envía role=2 cuando se elige Productor', (
      WidgetTester tester,
    ) async {
      await pumpRegister(tester);
      await fillHappyPath(tester, role: 'Productor');
      await tapSubmit(tester);

      expect(repository.received!.role, RegisterRole.producer);
      expect(repository.received!.role.roleId, 2);
    });

    testWidgets('bloquea el envío si el formulario es inválido', (
      WidgetTester tester,
    ) async {
      await pumpRegister(tester);
      await tester.tap(find.text('Comprador'));
      await tester.pump();
      await tapSubmit(tester);

      expect(repository.received, isNull);
      expect(find.text('Ingresa tu nombre'), findsOneWidget);
      expect(find.text('Ingresa tu correo electrónico'), findsOneWidget);
      expect(find.text('Ingresa tu número de teléfono'), findsOneWidget);
    });

    testWidgets('rechaza contraseña corta, correo inválido y teléfono corto', (
      WidgetTester tester,
    ) async {
      await pumpRegister(tester);
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

      expect(repository.received, isNull);
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

    testWidgets('muestra SnackBar de error si el repository lanza', (
      WidgetTester tester,
    ) async {
      final _RecordingRepository failing = _RecordingRepository(
        shouldFail: true,
      );
      await tester.pumpWidget(
        MaterialApp(home: RegisterView(repository: failing)),
      );
      await fillHappyPath(tester);
      await tapSubmit(tester);

      expect(failing.received, isNotNull);
      expect(
        find.text('No se pudo crear la cuenta. Intenta de nuevo.'),
        findsOneWidget,
      );
      // El botón vuelve a estar disponible para reintentar.
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets(
      'departamento y municipio son opcionales y se omiten si vacíos',
      (WidgetTester tester) async {
        await pumpRegister(tester);
        await fillHappyPath(tester);
        await tapSubmit(tester);

        expect(repository.received!.department, isEmpty);
        expect(repository.received!.municipality, isEmpty);
        expect(
          repository.received!.toJson().containsKey('department'),
          isFalse,
        );
      },
    );

    testWidgets('departamento y municipio se envían si se escriben', (
      WidgetTester tester,
    ) async {
      await pumpRegister(tester);
      await fillHappyPath(tester);
      await tester.enterText(
        fieldWithLabel('Departamento / Provincia'),
        'Masaya',
      );
      await tester.enterText(fieldWithLabel('Municipio'), 'Masate');
      await tester.pump();
      await tapSubmit(tester);

      expect(repository.received!.toJson()['department'], 'Masaya');
      expect(repository.received!.toJson()['municipality'], 'Masate');
    });

    testWidgets('a 1000px de ancho los campos van en dos columnas', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpRegister(tester);

      // Nombre y apellido comparten la misma fila en ancho.
      final double firstRowY = tester.getTopLeft(fieldWithLabel('Nombre')).dy;
      final double lastRowY = tester.getTopLeft(fieldWithLabel('Apellido')).dy;
      expect(firstRowY, lastRowY);

      // Y en ancho angosto se apilan.
      tester.view.physicalSize = const Size(400, 1400);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(fieldWithLabel('Apellido')).dy > firstRowY,
        isTrue,
      );
    });
  });
}
