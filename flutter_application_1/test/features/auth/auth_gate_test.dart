import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/models/auth_models.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/auth/auth_gate.dart';
import 'package:flutter_application_1/features/auth/auth_repository.dart';
import 'package:flutter_application_1/layout/buyer.dart';
import 'package:flutter_application_1/login.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({this.session, this.loginError})
    : super(apiClient: ApiClient(), tokenStore: TokenStore());

  final ({String token, String userId})? session;
  final Object? loginError;

  @override
  Future<({String token, String userId})?> restoreSession() async => session;

  @override
  Future<User> login({required String email, required String password}) async {
    if (loginError != null) throw loginError!;
    return const User(
      id: 'user-1',
      email: 'a@b.co',
      firstName: 'Flutter',
      lastName: 'Test',
      phoneNumber: '+50588887777',
      role: 2,
    );
  }

  @override
  Future<User> register({
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required int role,
    required String password,
    required String confirmPassword,
    String address = '',
    String department = '',
    String municipality = '',
  }) async => throw UnimplementedError();

  @override
  Future<void> logout() async {}
}

Future<void> pumpAuthGate(
  WidgetTester tester,
  AuthRepository authRepository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(0.8)),
        child: child!,
      ),
      home: AuthGate(authRepository: authRepository),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows LoginPage when there is no stored session', (
    tester,
  ) async {
    final fake = FakeAuthRepository();
    await pumpAuthGate(tester, fake);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(BuyerLayout), findsNothing);
  });

  testWidgets('shows BuyerLayout when a session is restored', (tester) async {
    final fake = FakeAuthRepository(
      session: (token: 'token-1', userId: 'user-1'),
    );
    await pumpAuthGate(tester, fake);

    expect(find.byType(BuyerLayout), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('successful login shows BuyerLayout', (tester) async {
    final fake = FakeAuthRepository();
    await pumpAuthGate(tester, fake);

    expect(find.byType(LoginPage), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'a@b.co');
    await tester.enterText(find.byType(TextField).at(1), 'Password123');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.byType(BuyerLayout), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('failed login shows error message and keeps LoginPage', (
    tester,
  ) async {
    final fake = FakeAuthRepository(
      loginError: ApiException(401, 'unauthorized'),
    );
    await pumpAuthGate(tester, fake);

    await tester.enterText(find.byType(TextField).at(0), 'a@b.co');
    await tester.enterText(find.byType(TextField).at(1), 'Password123');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
