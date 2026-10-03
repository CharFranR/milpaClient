import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class BuyerHome extends StatefulWidget {
  const BuyerHome({super.key});

  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(

        backgroundColor: AppColors.blackGreen,

        title: const Text('Inicio', style: AppText.appBarText)

      ),

    );
  }
}