import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart'; // Nuevo import
import 'package:LumorahAI/auth/auth_service.dart';
import 'package:LumorahAI/auth/login_page.dart';
import 'package:LumorahAI/auth/register_page.dart';
import 'package:LumorahAI/pages/screens/chats/ChatHistoryScreen.dart';
import 'package:LumorahAI/pages/screens/chats/ChatScreen.dart';
import 'package:LumorahAI/utils/colors.dart';
import 'package:LumorahAI/services/storage_service.dart';

class Menuprincipal extends StatefulWidget {
  @override
  _MenuprincipalState createState() => _MenuprincipalState();
}

class _MenuprincipalState extends State<Menuprincipal>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  late Animation<double> _sunAnimation;
  late AnimationController _sunController;
  final TextEditingController _textController = TextEditingController();

  final Color tiffanyColor = Color(0xFF88D5C2);
  final Color ivoryColor = Color(0xFFFDF8F2);
  final Color darkTextColor = Colors.black87;
  final Color lightTextColor = Colors.black;
  final Color micButtonColor = Color(0xFF4ECDC4);

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
  }

  @override
  void dispose() {
    _sunController.dispose();
    _textController.dispose();
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
          _showRegisterModal(context);
        },
        inputMode: 'keyboard',
      ),
    );
  }

  void _showRegisterModal(BuildContext context) {
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
  }

  Future<void> _handleAction(BuildContext context,
      {bool isVoice = false}) async {
    final isAuthenticated = await _isUserAuthenticated();
    if (!isAuthenticated) {
      _showLoginModal(context);
      return;
    }

    final inputMode = isVoice ? 'voice' : 'keyboard';
    final message = _textController.text.trim();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
          initialMessages: [],
          inputMode: inputMode,
          sessionId: null,
          initialMessage: message.isNotEmpty ? message : null,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var slideAnimation = animation.drive(tween);

          return SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );

    if (message.isNotEmpty) {
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tiffanyColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: lightTextColor.withOpacity(0.9)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: tiffanyColor.withOpacity(0.95),
          child: FutureBuilder<bool>(
            future: _isUserAuthenticated(),
            builder: (context, authSnapshot) {
              bool isAuthenticated = authSnapshot.data ?? false;
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  FutureBuilder<String?>(
                    future: _getUserName(),
                    builder: (context, userSnapshot) {
                      String headerText = isAuthenticated &&
                              userSnapshot.data != null
                          ? 'helloUser'.tr(
                              args: [userSnapshot.data!]) // Traducción dinámica
                          : 'helloLumorah'.tr(); // Traducción
                      return DrawerHeader(
                        decoration: BoxDecoration(
                          color: ivoryColor.withOpacity(0.7),
                        ),
                        child: Text(
                          headerText,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: darkTextColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.chat, color: lightTextColor),
                    title: Text(
                      'chat'.tr(), // Traducción
                      style: TextStyle(
                        color: lightTextColor,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  ChatScreen(
                            initialMessages: [],
                            inputMode: 'keyboard',
                            sessionId: null,
                          ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOut;

                            var tween = Tween(begin: begin, end: end)
                                .chain(CurveTween(curve: curve));
                            var slideAnimation = animation.drive(tween);

                            return SlideTransition(
                              position: slideAnimation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          transitionDuration: Duration(milliseconds: 300),
                        ),
                      );
                    },
                  ),
                  if (isAuthenticated)
                    ListTile(
                      leading: Icon(Icons.history, color: lightTextColor),
                      title: Text(
                        'chatHistory'.tr(), // Traducción
                        style: TextStyle(
                          color: lightTextColor,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatHistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ListTile(
                    leading: Icon(Icons.language, color: lightTextColor),
                    title: Text(
                      'changeLanguage'.tr(), // Traducción
                      style: TextStyle(
                        color: lightTextColor,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Configuración en desarrollo')),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.settings, color: lightTextColor),
                    title: Text(
                      'settings'.tr(), // Traducción
                      style: TextStyle(
                        color: lightTextColor,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Configuración en desarrollo')),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      isAuthenticated ? Icons.logout : Icons.login,
                      color: lightTextColor,
                    ),
                    title: Text(
                      isAuthenticated
                          ? 'logOut'.tr()
                          : 'logIn'.tr(), // Traducción
                      style: TextStyle(
                        color: lightTextColor,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (isAuthenticated) {
                        _signOut(context);
                      } else {
                        _showLoginModal(context);
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
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
                  'writeOrSpeak'.tr(), // Traducción
                  style: TextStyle(
                    fontSize: 30,
                    color: Colors.black,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  'iAmHere'.tr(), // Traducción
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black.withOpacity(0.9),
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'writeHint'.tr(), // Traducción
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: ivoryColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.mic, color: micButtonColor),
                            onPressed: () =>
                                _handleAction(context, isVoice: true),
                          ),
                          IconButton(
                            icon: Icon(Icons.send, color: micButtonColor),
                            onPressed: () => _handleAction(context),
                          ),
                        ],
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
      final dx = (size.width * ((i * 17 + progress * 120) % 100) / 50);
      final dy = size.height * ((i * 13 + progress * 90) % 100) / 100;
      final radius = 1.8 + (i % 4);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticulasPainter oldDelegate) => true;
}
