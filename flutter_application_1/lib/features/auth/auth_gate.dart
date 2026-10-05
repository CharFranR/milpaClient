import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/layout/buyer.dart';
import 'package:flutter_application_1/layout/farmer.dart';
import 'package:flutter_application_1/login.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _requestedLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (!session.authenticated) {
      _requestedLoad = false;
      return;
    }
    if (session.user == null && !session.loadingUser && !_requestedLoad) {
      _requestedLoad = true;
      session.loadUser();
    }
  }

  void _retry() {
    _requestedLoad = true;
    SessionScope.of(context).loadUser(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    if (session.restoring) return const _SplashScreen();
    if (!session.authenticated) return const LoginPage();
    final user = session.user;
    if (user == null) {
      if (session.loadingUser) return const _SplashScreen();
      return _LoadErrorScreen(onRetry: _retry);
    }
    return user.role == 1 ? const FarmerLayout() : const BuyerLayout();
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

class _LoadErrorScreen extends StatelessWidget {
  const _LoadErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whitemodeBackgrund,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_off_outlined, size: 56, color: AppTints.muted),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'No pudimos cargar tu cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tocá el botón para volver a intentar.',
                textAlign: TextAlign.center,
                style: AppText.bodySecondary,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blackGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(220, 52),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 22),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
