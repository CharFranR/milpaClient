import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/auth/auth_repository.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/layout/buyer.dart';
import 'package:flutter_application_1/login.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final SessionController _session = SessionController(
    authRepository:
        widget.authRepository ??
        AuthRepository(apiClient: ApiClient(), tokenStore: TokenStore()),
  );

  @override
  void initState() {
    super.initState();
    _session.restore();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: _session,
      child: ListenableBuilder(
        listenable: _session,
        builder: (context, _) {
          if (_session.restoring) return const _SplashScreen();
          return _session.authenticated
              ? const BuyerLayout()
              : const LoginPage();
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackGreen,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/LogoApp.png', width: 120),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
