import 'dart:math';
import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/pages/MenuPrincipal.dart';

class IntroPage extends StatefulWidget {
  final int pageIndex;

  const IntroPage({Key? key, required this.pageIndex}) : super(key: key);

  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
  late AnimationController _contentController;
  late AnimationController _particlesController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonScaleAnimation;

  final List<Map<String, dynamic>> _pageConfigs = [
    {
      'icon': Icons.message_rounded,
      'mainText': 'Puedes escribir\nlibremente aquí.',
      'mainTextSize': 24.0,
      'subText': '',
      'subTextSize': 0.0,
      'buttonLabel': 'Siguiente',
      'nextPage': (context) => IntroPage(pageIndex: 2),
    },
    {
      'icon': Icons.mic,
      'mainText': 'O hablar con\nel micrófono.',
      'mainTextSize': 30.0,
      'subText': 'Te escucho.',
      'subTextSize': 30.0,
      'buttonLabel': 'Siguiente',
      'nextPage': (context) => IntroPage(pageIndex: 3),
    },
    {
      'icon': null,
      'mainText': 'Puedes hablar con tu voz,\nen tu idioma y a tu ritmo.',
      'mainTextSize': 30.0,
      'subText': 'Lumorah te escucha con calma y sin juicios.',
      'subTextSize': 25.0,
      'buttonLabel': 'Iniciar',
      'nextPage': (context) => Menuprincipal(),
    },
  ];

  @override
  void initState() {
    super.initState();
    // Controller for content animations (fade, slide, button scale)
    _contentController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..forward();

    // Controller for particle animation
    _particlesController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configIndex = widget.pageIndex - 1;
    if (configIndex < 0 || configIndex >= _pageConfigs.length) {
      return Scaffold(
        body: Center(child: Text('Error: Invalid page index')),
      );
    }
    final config = _pageConfigs[configIndex];

    return Scaffold(
      backgroundColor: Color(0xFF88D5C2),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particlesController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ParticulasPainter(_particlesController.value),
                );
              },
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 20),
                _buildProgressBar(
                    currentPage: widget.pageIndex,
                    totalPages: _pageConfigs.length),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _contentController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.translate(
                          offset: _slideAnimation.value,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (config['icon'] != null)
                                Icon(
                                  config['icon'],
                                  size: 120,
                                  color: Colors.white,
                                ),
                              if (config['icon'] != null)
                                SizedBox(
                                    height: config['mainTextSize'] == 24.0
                                        ? 20
                                        : 30),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 25.0),
                                child: Text(
                                  config['mainText'],
                                  style: TextStyle(
                                    fontSize: config['mainTextSize'],
                                    color: Colors.black,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (config['subText'].isNotEmpty)
                                SizedBox(
                                    height: config['mainTextSize'] == 30.0
                                        ? 8
                                        : 28),
                              if (config['subText'].isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  child: Text(
                                    config['subText'],
                                    style: TextStyle(
                                      fontSize: config['subTextSize'],
                                      color: Colors.black,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.normal,
                                      height: 1.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              SizedBox(height: 40),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 50),
                  child: GestureDetector(
                    onTapDown: (_) {
                      _contentController.reverse();
                    },
                    onTapUp: (_) {
                      _contentController.forward();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: config['nextPage']),
                      );
                    },
                    child: ScaleTransition(
                      scale: _buttonScaleAnimation,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: config['nextPage']),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFDF8F2),
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 80, vertical: 15),
                          elevation: 2,
                        ),
                        child: Text(
                          config['buttonLabel'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  Widget _buildProgressBar(
      {required int currentPage, required int totalPages}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        child: LinearProgressIndicator(
          value: currentPage / totalPages,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _ParticulasPainter extends CustomPainter {
  final double progress;
  final Random _random = Random();

  _ParticulasPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 25; i++) {
      final dx = (size.width * ((i * 17 + progress * 120) % 100) / 100);
      final dy = size.height * ((i * 13 + progress * 90) % 100) / 100;
      final radius = 1.8 + (i % 4);
      paint.color =
          Colors.white.withOpacity(0.1 + (_random.nextDouble() * 0.1));
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticulasPainter oldDelegate) => true;
}
