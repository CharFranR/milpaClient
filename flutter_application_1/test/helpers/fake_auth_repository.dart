import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/models/auth_models.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/auth/auth_repository.dart';

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({this.session, this.loginError, this.registerError})
    : super(apiClient: ApiClient(), tokenStore: TokenStore());

  final ({String token, String userId})? session;
  final Object? loginError;
  final Object? registerError;

  int registerCalls = 0;
  int loginCalls = 0;
  int logoutCalls = 0;
  int? lastRegisteredRole;
  String? lastRegisteredEmail;

  @override
  Future<({String token, String userId})?> restoreSession() async => session;

  @override
  Future<User> login({required String email, required String password}) async {
    loginCalls++;
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
  }) async {
    registerCalls++;
    lastRegisteredRole = role;
    lastRegisteredEmail = email;
    if (registerError != null) throw registerError!;
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
  Future<void> logout() async {
    logoutCalls++;
  }
}
