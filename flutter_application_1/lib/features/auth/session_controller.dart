import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/models/auth_models.dart';
import 'package:flutter_application_1/features/auth/auth_repository.dart';
import 'package:flutter_application_1/features/auth/user_repository.dart';

class SessionController extends ChangeNotifier {
  SessionController({
    required this._authRepository,
    required this._userRepository,
  });

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  bool _restoring = true;
  bool _authenticated = false;
  User? _user;
  bool _loadingUser = false;

  bool get restoring => _restoring;
  bool get authenticated => _authenticated;
  User? get user => _user;
  bool get loadingUser => _loadingUser;

  Future<void> restore() async {
    try {
      final session = await _authRepository.restoreSession();
      _authenticated = session != null;
    } catch (_) {
      _authenticated = false;
    }
    _restoring = false;
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    _user = await _authRepository.login(email: email, password: password);
    _authenticated = true;
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required int role,
    required String password,
    required String confirmPassword,
    String department = '',
    String municipality = '',
  }) async {
    await _authRepository.register(
      email: email,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      role: role,
      password: password,
      confirmPassword: confirmPassword,
      department: department,
      municipality: municipality,
    );
    _user = await _authRepository.login(email: email, password: password);
    _authenticated = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authRepository.logout();
    _authenticated = false;
    _user = null;
    notifyListeners();
  }

  Future<void> loadUser({bool force = false}) async {
    if (_user != null && !force) return;
    _loadingUser = true;
    Future<void>.microtask(notifyListeners);
    try {
      _user = await _userRepository.fetchCurrent();
    } catch (_) {
    } finally {
      _loadingUser = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? address,
    String? department,
    String? municipality,
  }) async {
    _user = await _userRepository.updateCurrent(
      email: email,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      address: address,
      department: department,
      municipality: municipality,
    );
    notifyListeners();
  }
}

class SessionScope extends InheritedNotifier<SessionController> {
  const SessionScope({
    super.key,
    required SessionController controller,
    required super.child,
  }) : super(notifier: controller);

  static SessionController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope no encontrado');
    return scope!.notifier!;
  }
}
