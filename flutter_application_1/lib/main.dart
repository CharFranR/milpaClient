import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/auth/auth_gate.dart';
import 'package:flutter_application_1/features/auth/auth_repository.dart';
import 'package:flutter_application_1/features/auth/session_controller.dart';
import 'package:flutter_application_1/features/auth/user_repository.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquea la orientación en vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, this.authRepository, this.userRepository});

  final AuthRepository? authRepository;
  final UserRepository? userRepository;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final ApiClient _apiClient = ApiClient();
  late final TokenStore _tokenStore = TokenStore();

  late final SessionController _session = SessionController(
    authRepository:
        widget.authRepository ??
        AuthRepository(apiClient: _apiClient, tokenStore: _tokenStore),
    userRepository:
        widget.userRepository ??
        UserRepository(apiClient: _apiClient, tokenStore: _tokenStore),
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
      child: MaterialApp(
        // home: Scaffold(body: Center(child: Text('Bonito Joven!'))),

        debugShowCheckedModeBanner: false,

        theme: ThemeData(
          fontFamily: AppFonts.body,
          useMaterial3: true,
          brightness: Brightness.light,
        ),

        // home: const LoginPage(),
        home: const AuthGate(),
      ),
    );
  }
}
