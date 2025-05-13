import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:LumorahAI/auth/auth_service.dart';
import 'package:LumorahAI/auth/login_page.dart';
import 'package:LumorahAI/auth/register_page.dart';
import 'package:LumorahAI/pages/IntroPage.dart';
import 'package:LumorahAI/utils/colors.dart';
import 'package:LumorahAI/services/storage_service.dart';
import 'package:audioplayers/audioplayers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _sunController;
  late Animation<double> _sunAnimation;

  final Color tiffanyColor = Color(0xFF88D5C2);
  final Color ivoryColor = Color(0xFFFDF8F2);
  final Color darkTextColor = Colors.black87;
  final Color lightTextColor = Colors.white;

  @override
  void initState() {
    super.initState();

    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _sunAnimation = Tween<double>(begin: 130.0, end: 200.0).animate(
      CurvedAnimation(parent: _sunController, curve: Curves.easeInOut),
    );

    _loadSoundPreference(); // Cargar preferencia de sonido al iniciar
  }

  Future<void> _loadSoundPreference() async {
    final soundEnabled =
        await _storageService.getString('sound_enabled') == 'true' ||
            await _storageService.getString('sound_enabled') ==
                null; // Por defecto true si no está configurado
    if (soundEnabled) {
      _playWelcomeSound();
    }
  }

 Future<void> _playWelcomeSound() async {
  try {
    await _audioPlayer.setVolume(0.5); // Establecer volumen al 50%
    await _audioPlayer.play(AssetSource('sounds/sonido_inicial.mp3'));
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reproducir el sonido: $e'),
          backgroundColor: LumorahColors.error,
        ),
      );
    }
  }
}


  @override
  void dispose() {
    _sunController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<bool> _isUserAuthenticated() async {
    final token = await _storageService.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> _getUserName() async {
    final user = await _storageService.getUser();
    return user?.nombre;
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _authService.logout();
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: ${e.toString()}'),
          backgroundColor: LumorahColors.error,
        ),
      );
    }
  }

  void _showLoginModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LoginModal(
        showRegisterPage: () {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => RegisterModal(
              showLoginPage: () {
                Navigator.pop(context);
                _showLoginModal(context);
              },
              inputMode: 'keyboard',
            ),
          );
        },
        inputMode: 'keyboard',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tiffanyColor,
      body: Stack(
        children: [
          Positioned.fill(child: ParticulasFlotantes()),
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _sunAnimation,
                builder: (context, child) {
                  return Container(
                    width: _sunAnimation.value,
                    height: _sunAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFE5B4).withOpacity(0.7),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFFE5B4).withOpacity(0.8),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 180),
                Text(
                  'helloLumorah'.tr(),
                  style: TextStyle(
                    fontSize: 35,
                    color: Colors.black,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  'accompanyText'.tr(),
                  style: TextStyle(
                    fontSize: 25,
                    color: Colors.black.withOpacity(0.9),
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IntroPage(pageIndex: 1),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFDF8F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                  ),
                  child: Text(
                    'nextButton'.tr(),
                    style: TextStyle(
                      color: darkTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ParticulasFlotantes extends StatefulWidget {
  @override
  _ParticulasFlotantesState createState() => _ParticulasFlotantesState();
}

class _ParticulasFlotantesState extends State<ParticulasFlotantes>
    with SingleTickerProviderStateMixin {
  late AnimationController _particlesController;

  @override
  void initState() {
    super.initState();
    _particlesController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _particlesController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticulasPainter(_particlesController.value),
        );
      },
    );
  }
}

class _ParticulasPainter extends CustomPainter {
  final double progress;
  final Random _random = Random();

  _ParticulasPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 25; i++) {
      final dx = (size.width * ((i * 17 + progress * 120) % 100) / 100);
      final dy = (size.height * ((i * 13 + progress * 90) % 100) / 100);
      final radius = 1.8 + (i % 4);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticulasPainter oldDelegate) => true;
}
