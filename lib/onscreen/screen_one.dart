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
import 'constants2.dart';

class OnboardingScreenOne extends StatelessWidget {
  final PageController pageController;

  OnboardingScreenOne({required this.pageController});

  @override
  Widget build(BuildContext context) {
    final sizeReference = 700.0;

    double getResponsiveText(double size) =>
        size * sizeReference / MediaQuery.of(context).size.longestSide;

    Size size = MediaQuery.of(context).size;
    double screenHeight = size.height;
    double screenWidth = size.width;

    final double itemHeight = (size.height - kToolbarHeight - 24) / 2;
    final double itemWidth = size.width / 1.6;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
         body: Container(
          child: Stack(
            children: [
              Particles(
                awayRadius: 150,
                particles: ParticleUtils.createParticles(
                  numberOfParticles: 50,
                  color: Colors.orange, 
                  maxSize: 5.0,
                  maxVelocity: 30,
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
                    padding: const EdgeInsets.only(top: 80),
                    child: Container(
                      height: 300,
                      width: 300,
                      child: Lottie.asset('assets/images/animaciondos.json'),
                    ),
                  ),
                  ClipPath(
                    clipper: SlandingClipper(),
                    child: Container(
                      height: size.height * 0.5,
                      color: Colors.lightBlue[100],
                    ),
                  )
                ],
              ),
              Positioned(
                top: size.height * 0.55,
                child: Container(
                  width: size.width,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Tu fisioterapeuta, más cerca que nunca",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                          fontSize: getResponsiveText(32),
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: size.height * 0.03),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
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
                                  text:
                                      "Encuentra expertos cerca de ti y empieza tu recuperación hoy mismo. "),
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