import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/core/models/auth_models.dart';
import 'package:flutter_application_1/core/photo_picker.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/features/buyer/profile.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_photo_picker.dart';
import '../../helpers/fake_user_repository.dart';

const User userWithoutPhoto = User(
  id: 'user-1',
  email: 'oscar@milpa.com',
  firstName: 'Oscar',
  lastName: 'Reyes',
  phoneNumber: '+505 8888 1234',
  role: 2,
);

const User userWithPhoto = User(
  id: 'user-1',
  email: 'oscar@milpa.com',
  firstName: 'Oscar',
  lastName: 'Reyes',
  phoneNumber: '+505 8888 1234',
  role: 2,
  photoUrl: 'uploads/foto-perfil.jpg',
);

Widget wrap({
  required FakeUserRepository users,
  required PhotoPicker picker,
}) => SessionScope(
  controller: SessionController(
    authRepository: FakeAuthRepository(),
    userRepository: users,
  ),
  child: MaterialApp(home: BuyerProfile(photoPicker: picker)),
);

const ValueKey<String> avatarFallback = ValueKey<String>('avatarFallback');

void main() {
  testWidgets('sin foto muestra un avatar genérico, no un asset fijo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        users: FakeUserRepository(current: userWithoutPhoto),
        picker: FakePhotoPicker(),
      ),
    );
    await tester.pump();

    expect(find.byKey(avatarFallback), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('con foto del server pide la imagen al endpoint de imágenes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        users: FakeUserRepository(current: userWithPhoto),
        picker: FakePhotoPicker(),
      ),
    );
    await tester.pump();

    final Image avatar = tester.widget<Image>(find.byType(Image));
    expect(
      (avatar.image as NetworkImage).url,
      endsWith('/images/foto-perfil.jpg'),
    );
  });

  testWidgets('tocar el avatar sube la foto elegida', (
    WidgetTester tester,
  ) async {
    final FakeUserRepository users = FakeUserRepository(
      current: userWithoutPhoto,
    );
    final FakePhotoPicker picker = FakePhotoPicker(
      result: const PickedPhoto(path: '/tmp/foto.jpg', filename: 'elegida.jpg'),
    );

    await tester.pumpWidget(wrap(users: users, picker: picker));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.photo_camera));
    await tester.pumpAndSettle();

    expect(picker.calls, 1);
    expect(users.photoCalls, 1);
    expect(users.lastPhotoPath, '/tmp/foto.jpg');
    expect(users.lastPhotoFilename, 'elegida.jpg');
    expect(find.text('Foto actualizada'), findsOneWidget);
  });

  testWidgets('si la subida falla lo avisa y no queda foto', (
    WidgetTester tester,
  ) async {
    final FakeUserRepository users = FakeUserRepository(
      current: userWithoutPhoto,
    )..photoError = Exception('boom');
    final FakePhotoPicker picker = FakePhotoPicker(
      result: const PickedPhoto(path: '/tmp/foto.jpg', filename: 'elegida.jpg'),
    );

    await tester.pumpWidget(wrap(users: users, picker: picker));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.photo_camera));
    await tester.pumpAndSettle();

    expect(find.text('No pudimos actualizar tu foto'), findsOneWidget);
    expect(find.byKey(avatarFallback), findsOneWidget);
  });
}
