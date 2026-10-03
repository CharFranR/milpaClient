import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/models/auth_models.dart';
import 'package:flutter_application_1/core/token_store.dart';

class AuthRepository {
  AuthRepository({required ApiClient apiClient, required this._tokenStore})
    : _api = apiClient;

  final ApiClient _api;
  final TokenStore _tokenStore;

  Future<User> login({required String email, required String password}) async {
    final dynamic json = await _api.post(
      '/auth/login',
      body: <String, dynamic>{'email': email, 'password': password},
    );
    final LoginResponse response = LoginResponse.fromJson(
      json as Map<String, dynamic>,
    );
    await _tokenStore.save(
      token: response.accessToken,
      userId: response.user.id,
    );
    return response.user;
  }

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
  }) async {
    final dynamic json = await _api.post(
      '/auth/register',
      body: <String, dynamic>{
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'role': role,
        'password': password,
        'confirm_password': confirmPassword,
        if (address.isNotEmpty) 'address': address,
        if (department.isNotEmpty) 'department': department,
        if (municipality.isNotEmpty) 'municipality': municipality,
      },
    );
    return User.fromJson(json as Map<String, dynamic>);
  }

  Future<({String token, String userId})?> restoreSession() async {
    final String? token = await _tokenStore.readToken();
    final String? userId = await _tokenStore.readUserId();
    if (token == null || userId == null) return null;
    return (token: token, userId: userId);
  }

  Future<void> logout() => _tokenStore.clear();
}
