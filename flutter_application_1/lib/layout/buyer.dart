import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/buyer/explore.dart';
import 'package:flutter_application_1/features/buyer/home.dart';
import 'package:flutter_application_1/features/buyer/messages.dart';
import 'package:flutter_application_1/features/buyer/profile.dart';
import 'package:flutter_application_1/ui/app_tokens.dart';

class BuyerLayout extends StatefulWidget {
  const BuyerLayout({super.key});

  @override
  State<BuyerLayout> createState() => _BuyerLayoutState();
}

class _BuyerLayoutState extends State<BuyerLayout> {

  int _currentIndex = 0;

  List<Widget> pages = [
    BuyerHome(),
    BuyerExplore(),
    BuyerMessages(),
    BuyerProfile(),

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: AppColors.whitemodeBackgrund,

      body: pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        fixedColor: AppColors.blackGreen,
        items: [

          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.apps_outlined), label: 'Explorar'),
          BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Mensajes'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outlined), label: 'Perfil')

        ],
        currentIndex: _currentIndex,
        onTap: (index){
          setState(() {
            _currentIndex = index;
          });
        },
      )

    );
  }
}