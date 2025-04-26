import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:lottie/lottie.dart';
import 'package:particles_flutter/particles_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_auth_crudd10/auth/auth_check.dart';
import 'package:user_auth_crudd10/onscreen/screen_two.dart';
import 'package:user_auth_crudd10/onscreen/slanding_clipper.dart';
import 'package:user_auth_crudd10/utils/ParticleUtils.dart';
import 'package:user_auth_crudd10/utils/colors.dart';
import 'constants2.dart';

class OnBoardingCuatro extends StatelessWidget {
  final PageController pageController;

  OnBoardingCuatro({required this.pageController});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final sizeReference = 700.0;
    double screenHeight = size.height;
    double screenWidth = size.width;

    double getResponsiveText(double size) =>
        size * sizeReference / MediaQuery.of(context).size.longestSide;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          child: Stack(
            children: [
              // Partículas con color de la paleta Lumorah
              Particles(
                awayRadius: 150,
                particles: ParticleUtils.createParticles(
                  numberOfParticles: 50,
                  color: LumorahColors.primaryLight,
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
                  Padding(
                    padding: const EdgeInsets.only(top: 140),
                    child: Container(
                      width: 300,
                      height: 300,
                      child: Lottie.asset('assets/images/animaciontres.json'),
                    ),
                  ),
                  RotatedBox(
                    quarterTurns: 2,
                    child: ClipPath(
                      clipper: SlandingClipper(),
                      child: Container(
                        height: size.height * 0.4,
                        color: LumorahColors.primaryLighter,
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: size.height * 0.60,
                child: Container(
                  width: size.width,
                  padding: EdgeInsets.all(appPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Juntos hacia el bienestar",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: LumorahColors.darkBackground,
                          fontSize: 27,
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: RichText(
                          textAlign: TextAlign.start,
                          text: TextSpan(
                            style: TextStyle(
                                color: LumorahColors.textLight, fontSize: 16),
                            children: <TextSpan>[
                              TextSpan(
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: getResponsiveText(24),
                                      color: LumorahColors.textLight),
                                  text:
                                      "Manten la comunicación con tu fisioterapeuta y "),
                              TextSpan(
                                  style: TextStyle(
                                    color: LumorahColors.textLight,
                                    fontSize: getResponsiveText(24),
                                  ),
                                  text: "sigue tu avance en un solo lugar"),
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
                          border: Border.all(
                              color: LumorahColors.primaryDark, width: 2),
                          shape: BoxShape.circle,
                          color: Colors.white),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: appPadding / 4),
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: LumorahColors.primaryDark, width: 2),
                          shape: BoxShape.circle,
                          color: Colors.white),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: appPadding / 4),
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: LumorahColors.primaryDark, width: 2),
                          shape: BoxShape.circle,
                          color: LumorahColors.primary),
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
                            color: Colors.white, // Mantenido para contraste
                            fontSize: 20.0,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: appPadding),
                      child: FloatingActionButton(
                        onPressed: () {
                          _storeOnboardInfo();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AuthCheckMain(),
                            ),
                          );
                        },
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.check,
                          color: LumorahColors.primary,
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
