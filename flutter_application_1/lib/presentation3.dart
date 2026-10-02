import 'package:flutter/material.dart';
import 'package:flutter_application_1/presets.dart';
import 'package:flutter_application_1/login.dart';


class Presentation3 extends StatelessWidget {
  const Presentation3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: AppColors.whitemodeBackgrund,

      body: SafeArea(

        child: Center(

          child: Column(

            children: [

              const Spacer(flex: 2),

              Expanded(

                flex: 10,

                child: Column(

                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,

                  children: [

                    Expanded(
                      flex: 4,
                      child: _MainLogo(logoPath: 'assets/paquete.png'),
                    ),

                    Expanded(
                      flex: 3,
                      child: _BuildText(),
                    ),

          
                    Expanded(
                      flex: 3,
                      child: _Buttons(),
                    )


                  ],



                ),


              ),


              const Spacer(flex: 1),

            ],
          ),
        ),
      ),

    );
  }
}


class _MainLogo extends StatelessWidget {

  final String logoPath;
  const _MainLogo({required this.logoPath});

  @override
  Widget build(BuildContext context) {
    return Image.asset(logoPath);
  }
}


class _BuildText extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    final width = MediaQuery.of(context).size.width;

    return Column(

      children: [
      
        Padding(

          padding: EdgeInsets.symmetric(horizontal: width * 0.1),

          child: Text(
            'Publica tus productos',
            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,

            ),

          ),
        ),


        Padding(

          padding: EdgeInsets.symmetric(horizontal: width * 0.1),

          child: Text(
            'Si eres productor, crea tu tienda en minutos y llega a compradores de toda la región fácilmente.',

            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: 16,
              color: AppColors.dark,

            ),
          )
        ),

      ],

    );
  }
}


class _Buttons extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Column(

      children: [

        TextButton(
          onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          }, 
          child: Container(

            decoration: BoxDecoration(

              color: AppColors.blackGreen,
              borderRadius: BorderRadius.circular(10),

            ),


            padding: EdgeInsets.symmetric(horizontal: width * 0.3, vertical: height * 0.02),

            child: Text(
              'Comenzar',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 20,
                color: AppColors.whitemodeBackgrund,

              ),


            )),

        ),

      ],


    )
    ;
  }
}