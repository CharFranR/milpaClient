import 'package:flutter/material.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class BuyerExplore extends StatefulWidget {
  const BuyerExplore({super.key});

  @override
  State<BuyerExplore> createState() => _BuyerExploreState();
}

class _BuyerExploreState extends State<BuyerExplore> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(

      appBar: AppBar(

        backgroundColor: AppColors.blackmodeBackgrund,

        title: const Text('Explorar', style: AppText.appBarText)

      ),

    );
  }
}