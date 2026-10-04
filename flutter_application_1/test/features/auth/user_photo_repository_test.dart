import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/models/auth_models.dart';
import 'package:flutter_application_1/features/auth/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'auth_repository_test.dart' show FakeTokenStore;

Map<String, dynamic> userJson(String photoUrl) => <String, dynamic>{
  'id': 'user-1',
  'email': 'oscar@milpa.com',
  'first_name': 'Oscar',
  'last_name': 'Reyes',
  'phone_number': '88881234',
  'role': 2,
  'photo_url': photoUrl,
};

void main() {
  test('sube la foto como multipart con el token y recarga el usuario', () async {
    final Directory dir = Directory.systemTemp.createTempSync('milpa-photo');
    final File file = File('${dir.path}/foto.jpg')
      ..writeAsBytesSync(<int>[1, 2, 3]);

    http.Request? upload;
    final MockClient mockClient = MockClient((http.Request request) async {
      if (request.method == 'POST') {
        upload = request;
        return http.Response('{"data":null}', 200);
      }
      return http.Response(
        jsonEncode(<String, dynamic>{'data': userJson('uploads/foto.jpg')}),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });

    final FakeTokenStore store = FakeTokenStore();
    await store.save(token: 'tok-1', userId: 'user-1');

    final UserRepository repository = UserRepository(
      apiClient: ApiClient(httpClient: mockClient),
      tokenStore: store,
    );

    final User user = await repository.uploadPhoto(
      filePath: file.path,
      filename: 'foto.jpg',
    );

    expect(upload, isNotNull);
    expect(upload!.url.path, endsWith('/users/user-1/photo'));
    expect(upload!.headers['authorization'], 'Bearer tok-1');
    expect(upload!.body, contains('name="photo"'));
    expect(upload!.body, contains('foto.jpg'));
    expect(user.photoUrl, 'uploads/foto.jpg');
    expect(user.photoSrc, endsWith('/images/foto.jpg'));

    dir.deleteSync(recursive: true);
  });

  test('sin sesión no toca la red', () async {
    final MockClient mockClient = MockClient((http.Request request) async {
      fail('no debería llegar ninguna request');
    });

    final UserRepository repository = UserRepository(
      apiClient: ApiClient(httpClient: mockClient),
      tokenStore: FakeTokenStore(),
    );

    expect(
      () => repository.uploadPhoto(filePath: '/tmp/x.jpg', filename: 'x.jpg'),
      throwsA(isA<ApiException>()),
    );
  });
}
