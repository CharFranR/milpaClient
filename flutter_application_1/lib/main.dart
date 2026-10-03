import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/layout/buyer.dart';
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

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // home: Scaffold(body: Center(child: Text('Bonito Joven!'))),

      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        fontFamily: AppFonts.body,
        useMaterial3: true,
        brightness: Brightness.light,
      ),

      // home: const LoginPage(),
      home: const BuyerLayout(),
    );
  }
}
