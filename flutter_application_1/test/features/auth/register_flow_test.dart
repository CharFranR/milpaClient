import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/auth/register_view.dart';
import 'package:flutter_application_1/layout/buyer.dart';
import 'package:flutter_application_1/login.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  testWidgets('registrarse desde login crea la cuenta y entra al inicio', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 0.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final fake = FakeAuthRepository();
    await tester.pumpWidget(MainApp(authRepository: fake));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);

    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterView), findsOneWidget);

    await tester.tap(find.text('Comprador'));
    await tester.pump();

    final Finder fields = find.descendant(
      of: find.byType(RegisterView),
      matching: find.byType(TextField),
    );

    await tester.enterText(fields.at(0), 'Juan');
    await tester.enterText(fields.at(1), 'Pérez');
    await tester.enterText(fields.at(2), 'a@b.co');
    await tester.enterText(fields.at(3), '88887777');
    await tester.enterText(fields.at(4), 'Password123');
    await tester.enterText(fields.at(5), 'Password123');
    await tester.enterText(fields.at(6), 'Barrio Central, casa 3');
    await tester.enterText(fields.at(7), 'Masaya');
    await tester.enterText(fields.at(8), 'Masate');

    final Finder submit = find.widgetWithText(TextButton, 'Crear cuenta');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(fake.registerCalls, 1);
    expect(fake.loginCalls, 1);
    expect(fake.lastRegisteredRole, 2);
    expect(fake.lastRegisteredEmail, 'a@b.co');
    expect(fake.lastRegisteredAddress, 'Barrio Central, casa 3');
    expect(find.byType(BuyerLayout), findsOneWidget);
    expect(find.byType(RegisterView), findsNothing);
  });
}
