import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/models/auth_models.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/features/buyer/edit_profile.dart';
import 'package:flutter_application_1/features/buyer/profile.dart';
import 'package:flutter_application_1/ui/labeled_field.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_user_repository.dart';

const User testUser = User(
  id: 'user-1',
  email: 'oscar@milpa.com',
  firstName: 'Oscar',
  lastName: 'Reyes',
  phoneNumber: '+505 8888 1234',
  role: 2,
  department: 'Masaya',
  municipality: 'Masate',
);

Widget wrap({
  required FakeAuthRepository auth,
  required FakeUserRepository users,
}) => SessionScope(
  controller: SessionController(authRepository: auth, userRepository: users),
  child: const MaterialApp(home: BuyerProfile()),
);

Finder fieldWithLabel(String label) {
  return find.descendant(
    of: find.ancestor(
      of: find.text(label),
      matching: find.byType(LabeledField),
    ),
    matching: find.byType(TextFormField),
  );
}

void main() {
  testWidgets('shows the loaded user data from the repository', (
    WidgetTester tester,
  ) async {
    final auth = FakeAuthRepository();
    final users = FakeUserRepository(current: testUser);

    await tester.pumpWidget(wrap(auth: auth, users: users));
    await tester.pump();

    expect(find.text('Oscar Reyes'), findsNWidgets(2));
    expect(find.text('oscar@milpa.com'), findsNWidgets(2));
    expect(find.text('+505 8888 1234'), findsOneWidget);
    expect(find.text('Masate, Masaya'), findsOneWidget);
    expect(users.fetchCalls, 1);
  });

  testWidgets('shows retry UI when fetching fails and then loads the user', (
    WidgetTester tester,
  ) async {
    final auth = FakeAuthRepository();
    final users = FakeUserRepository(current: testUser)
      ..fetchError = const ApiException(500, 'boom');

    await tester.pumpWidget(wrap(auth: auth, users: users));
    await tester.pump();

    expect(find.text('No se pudo cargar el perfil'), findsOneWidget);

    users.fetchError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(find.text('Oscar Reyes'), findsNWidgets(2));
    expect(users.fetchCalls, 2);
  });

  testWidgets('tapping Cerrar sesión logs out', (WidgetTester tester) async {
    final auth = FakeAuthRepository();
    final users = FakeUserRepository(current: testUser);

    await tester.pumpWidget(wrap(auth: auth, users: users));
    await tester.pump();

    await tester.ensureVisible(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pump();

    expect(auth.logoutCalls, 1);
  });

  testWidgets('edit flow saves changes and shows the updated profile', (
    WidgetTester tester,
  ) async {
    final auth = FakeAuthRepository();
    final users = FakeUserRepository(current: testUser);

    await tester.pumpWidget(wrap(auth: auth, users: users));
    await tester.pump();

    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfilePage), findsOneWidget);
    expect(find.text('Oscar'), findsOneWidget);

    await tester.enterText(fieldWithLabel('Nombre'), 'Carlos');
    await tester.pump();

    final Finder save = find.text('Guardar cambios');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(users.updateCalls, 1);
    expect(users.lastUpdate['firstName'], 'Carlos');
    expect(find.byType(EditProfilePage), findsNothing);
    expect(find.text('Carlos Reyes'), findsNWidgets(2));
  });
}
