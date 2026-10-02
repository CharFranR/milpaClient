import 'package:flutter/material.dart';
import 'package:flutter_application_1/presentation1.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      // home: Scaffold(body: Center(child: Text('Bonito Joven!'))),

      debugShowCheckedModeBanner: false,

      theme: ThemeData(fontFamily: 'Inter', useMaterial3: true, brightness: Brightness.light),

      // home: const LoginPage(),

      



      home: const Presentation1()
    
    );
  }
}
