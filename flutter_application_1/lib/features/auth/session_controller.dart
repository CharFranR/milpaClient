import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/auth/auth_repository.dart';

class SessionController extends ChangeNotifier {
  SessionController({required this._authRepository});

  final AuthRepository _authRepository;

  bool _restoring = true;
  bool _authenticated = false;

  bool get restoring => _restoring;
  bool get authenticated => _authenticated;

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
    await _authRepository.login(email: email, password: password);
    _authenticated = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authRepository.logout();
    _authenticated = false;
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
