import 'package:flutter_application_1/core/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiConfig webSocketUriFrom', () {
    test('cambia http por ws y agrega la ruta del socket', () {
      final Uri uri = ApiConfig.webSocketUriFrom(
        'http://10.0.2.2:8080/api/v1',
        'conversation-1',
      );

      expect(uri.toString(), 'ws://10.0.2.2:8080/api/v1/ws/conversation-1');
    });

    test('cambia https por wss', () {
      final Uri uri = ApiConfig.webSocketUriFrom(
        'https://api.milpa.com/api/v1',
        'conversation-2',
      );

      expect(uri.toString(), 'wss://api.milpa.com/api/v1/ws/conversation-2');
    });

    test('agrega la ruta del socket cuando la base no tiene ruta', () {
      final Uri uri = ApiConfig.webSocketUriFrom(
        'http://localhost:8080',
        'conversation-3',
      );

      expect(uri.toString(), 'ws://localhost:8080/ws/conversation-3');
    });

    test('ignora la barra final de la ruta base', () {
      final Uri uri = ApiConfig.webSocketUriFrom(
        'http://localhost:8080/api/v1/',
        'conversation-4',
      );

      expect(uri.toString(), 'ws://localhost:8080/api/v1/ws/conversation-4');
    });
  });

  group('ApiConfig webSocketUri', () {
    test('delega en la URL base configurada', () {
      final Uri uri = ApiConfig.webSocketUri('conversation-9');

      expect(uri.scheme, 'ws');
      expect(uri.path, '/api/v1/ws/conversation-9');
    });
  });
}
