import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';

class ReportRepository {
  ReportRepository({
    required ApiClient apiClient,
    required this._tokenStore,
  }) : _api = apiClient;

  final ApiClient _api;
  final TokenStore _tokenStore;

  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    final String token = await _readTokenOrThrow();
    await _api.post(
      '/reports/',
      token: token,
      body: <String, String>{
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason,
      },
    );
  }

  Future<String> _readTokenOrThrow() async {
    final String? token = await _tokenStore.readToken();
    if (token == null) {
      throw const ApiException(401, 'Sesión no disponible');
    }
    return token;
  }
}
