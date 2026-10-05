import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/layout/buyer.dart';
import 'package:flutter_application_1/login.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_user_repository.dart';

Future<void> pumpMainApp(WidgetTester tester, FakeAuthRepository fake) async {
  tester.platformDispatcher.textScaleFactorTestValue = 0.8;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    MainApp(authRepository: fake, userRepository: FakeUserRepository()),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows LoginPage when there is no stored session', (
    tester,
  ) async {
    final fake = FakeAuthRepository();
    await pumpMainApp(tester, fake);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(BuyerLayout), findsNothing);
  });

  testWidgets('shows BuyerLayout when a session is restored', (tester) async {
    final fake = FakeAuthRepository(
      session: (token: 'token-1', userId: 'user-1'),
    );
    await pumpMainApp(tester, fake);

    expect(find.byType(BuyerLayout), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('successful login shows BuyerLayout', (tester) async {
    final fake = FakeAuthRepository();
    await pumpMainApp(tester, fake);

    expect(find.byType(LoginPage), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'a@b.co');
    await tester.enterText(find.byType(TextField).at(1), 'Password123');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(fake.loginCalls, 1);
    expect(find.byType(BuyerLayout), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('failed login shows error message and keeps LoginPage', (
    tester,
  ) async {
    final fake = FakeAuthRepository(
      loginError: ApiException(401, 'unauthorized'),
    );
    await pumpMainApp(tester, fake);

    await tester.enterText(find.byType(TextField).at(0), 'a@b.co');
    await tester.enterText(find.byType(TextField).at(1), 'Password123');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
