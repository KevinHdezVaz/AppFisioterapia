import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:lottie/lottie.dart';
import 'package:particles_flutter/particles_engine.dart';
 import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_auth_crudd10/auth/auth_check.dart';
import 'package:user_auth_crudd10/onscreen/screen_cuatro.dart';
import 'package:user_auth_crudd10/onscreen/screen_two.dart';
import 'package:user_auth_crudd10/onscreen/slanding_clipper.dart';
import 'package:user_auth_crudd10/utils/ParticleUtils.dart'; // Importa la utilidad
import 'constants2.dart';

class OnboardingScreenTwo extends StatelessWidget {
  final PageController pageController;

  OnboardingScreenTwo({required this.pageController});

  @override
  Widget build(BuildContext context) {
    final sizeReference = 700.0;

    double getResponsiveText(double size) =>
        size * sizeReference / MediaQuery.of(context).size.longestSide;

    Size size = MediaQuery.of(context).size;
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    final double itemHeight = (size.height - kToolbarHeight - 24) / 2;
    final double itemWidth = size.width / 1.6;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
         body: Container(
          child: Stack(
            children: [
              // Agregar partículas
              Particles(
                awayRadius: 150,
                particles: ParticleUtils.createParticles(
                  numberOfParticles: 50,
                  color: Colors.green, // Color visible contra fondo oscuro
                  maxSize: 5.0,
                  maxVelocity: 30.0,
                ),
                height: screenHeight,
                width: screenWidth,
                onTapAnimation: true,
                awayAnimationDuration: const Duration(milliseconds: 600),
                awayAnimationCurve: Curves.easeIn,
                enableHover: true,
                hoverRadius: 90,
                connectDots: false,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RotatedBox(
                    quarterTurns: 2,
                    child: ClipPath(
                      clipper: SlandingClipper(),
                      child: Container(
                        height: size.height * 0.5,
                        color: Colors.lightBlue[100],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 100), // Nota: 'bottom' en lugar de 'custom'
                    child: Container(
                      width: 300,
                      height: 300,
                      child: Lottie.asset('assets/images/animacionuno.json'),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: size.height * 0.05,
                child: Container(
                  width: size.width,
                  padding: EdgeInsets.all(appPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 90),
                        child: Text(
                          "Recupérate con confianza",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 27,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: size.height * 0.02,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: RichText(
                          textAlign: TextAlign.start,
                          text: TextSpan(
                            style: TextStyle(color: Colors.black, fontSize: 16),
                            children: <TextSpan>[
                              TextSpan(
                                  style: TextStyle(
                                      fontSize: getResponsiveText(24),
                                      fontFamily: 'Viga-Regular',
                                      color: Colors.black),
                                  text: "Ejercicios personalizados, videollamadas"),
                              TextSpan(
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    fontSize: getResponsiveText(24),
                                  ),
                                  text: " y seguimiento en tiempo real."),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 15,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: appPadding / 4),
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                          border: Border.all(color: black, width: 2),
                          shape: BoxShape.circle,
                          color: white),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: appPadding / 4),
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                          border: Border.all(color: black, width: 2),
                          shape: BoxShape.circle,
                          color: Colors.blue),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: appPadding / 4),
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                          border: Border.all(color: black, width: 2),
                          shape: BoxShape.circle,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: appPadding * 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          _storeOnboardInfo();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AuthCheckMain(),
                            ),
                          );
                        },
                        child: Text(
                          "OMITIR",
                          style: TextStyle(
                            color: Colors.white, // Color fijo
                            fontSize: 20.0,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: appPadding),
                      child: FloatingActionButton(
                        onPressed: () {
                          pageController.nextPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        backgroundColor: white,
                        child: Icon(
                          Icons.navigate_next_rounded,
                          color: black,
                          size: 30,
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _storeOnboardInfo() async {
    print("Shared pref called");
    int isViewed = 0;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('onBoard', isViewed);
    print(prefs.getInt('onBoard'));
  }
}