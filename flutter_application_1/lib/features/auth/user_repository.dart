import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/models/auth_models.dart';
import 'package:flutter_application_1/core/token_store.dart';

class UserRepository {
  UserRepository({required ApiClient apiClient, required this._tokenStore})
    : _api = apiClient;

  final ApiClient _api;
  final TokenStore _tokenStore;

  Future<User> fetchCurrent() async {
    final String? userId = await _tokenStore.readUserId();
    final String? token = await _tokenStore.readToken();
    if (userId == null || token == null) {
      throw const ApiException(401, 'Sesión no disponible');
    }
    final dynamic json = await _api.get('/users/$userId', token: token);
    return User.fromJson(json as Map<String, dynamic>);
  }

  Future<User> updateCurrent({
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? address,
    String? department,
    String? municipality,
    double? latitude,
    double? longitude,
  }) async {
    final String? userId = await _tokenStore.readUserId();
    final String? token = await _tokenStore.readToken();
    if (userId == null || token == null) {
      throw const ApiException(401, 'Sesión no disponible');
    }
    final Map<String, dynamic> body = <String, dynamic>{
      'email': ?email,
      'first_name': ?firstName,
      'last_name': ?lastName,
      'phone_number': ?phoneNumber,
      'address': ?address,
      'department': ?department,
      'municipality': ?municipality,
      'latitude': ?latitude,
      'longitude': ?longitude,
    };
    await _api.patch('/users/$userId', body: body, token: token);
    return fetchCurrent();
  }

  Future<User> uploadPhoto({
    required String filePath,
    required String filename,
  }) async {
    final String? userId = await _tokenStore.readUserId();
    final String? token = await _tokenStore.readToken();
    if (userId == null || token == null) {
      throw const ApiException(401, 'Sesión no disponible');
    }
    await _api.postMultipart(
      '/users/$userId/photo',
      field: 'photo',
      filePath: filePath,
      filename: filename,
      token: token,
    );
    return fetchCurrent();
  }
}
