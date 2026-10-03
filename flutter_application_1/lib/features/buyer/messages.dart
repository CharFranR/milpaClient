import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class BuyerMessages extends StatefulWidget {
  const BuyerMessages({super.key});

  @override
  State<BuyerMessages> createState() => _BuyerMessagesState();
}

class _BuyerMessagesState extends State<BuyerMessages> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(

        backgroundColor: AppColors.blackmodeBackgrund,

        title: const Text('Mensajes', style: AppText.appBarText)

      ),

    );
  }
}