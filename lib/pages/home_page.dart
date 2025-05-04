import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/auth/login_page.dart';
import 'package:user_auth_crudd10/auth/register_page.dart';
import 'package:user_auth_crudd10/pages/screens/chats/ChatHistoryScreen.dart';
import 'dart:async';
import 'dart:math';
import 'package:user_auth_crudd10/pages/screens/chats/ChatScreen.dart';
import 'dart:ui';
import 'package:user_auth_crudd10/utils/colors.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  late Animation<double> _animation;

  final List<String> frases = [
    'Tu espacio emocional está aquí.',
    'Un suspiro es suficiente para volver a ti.',
    'Escucha tu interior, él sabe el camino.',
    'Todo lo que sientes merece un lugar.',
    'Respira suave, estás en casa.',
    'Aquí puedes ser tú, sin juicio.',
    'La calma te encuentra cuando te detienes.',
    'Estás seguro, estás acompañado.',
    'Tu energía es valiosa.',
    'Hay belleza en cada emoción.',
    'Este momento también es amor.',
    'El silencio también habla de ti.',
    'Tu voz interna importa.',
    'Lumorah te sostiene, sin prisa.',
    'Puedes descansar aquí.',
    'Todo en ti es digno de ternura.',
    'Eres más que tus pensamientos.',
    'Cada emoción trae un mensaje.',
    'Hoy puedes elegir suavidad.',
    'Aquí empieza tu reconexión.',
  ];

  late Timer _timer;
  int _fraseIndex = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 90.0, end: 130.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _fraseIndex = Random().nextInt(frases.length);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<bool> _isUserAuthenticated() async {
    final token = await _storageService.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> _getUserName() async {
    final user = await _storageService.getUser();
    print('User: ${user?.toJson() ?? 'No user'}'); // Debug user data
    return user?.nombre;
  }

  Future<void> _signOut() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _authService.logout();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: ${e.toString()}'),
          backgroundColor: LumorahColors.error,
        ),
      );
    }
  }

  void _showLoginModal() {
    if (!mounted) return;

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
                _showLoginModal();
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
      backgroundColor: const Color(0xFF4BB6A8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white.withOpacity(0.9)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: Color(0xFF4BB6A8).withOpacity(0.95),
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
                      String headerText =
                          isAuthenticated && userSnapshot.data != null
                              ? 'Hola, ${userSnapshot.data}'
                              : 'Lumorah';
                      return DrawerHeader(
                        decoration: BoxDecoration(
                          color: Color(0xFFFFE5B4).withOpacity(0.7),
                        ),
                        child: Text(
                          headerText,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.chat, color: Colors.white),
                    title: Text(
                      'Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // En HomeScreen:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatMessages: [],
                            inputMode: 'keyboard',
                            sessionId: null, // Inicia sin sesión
                          ),
                        ),
                      );
                    },
                  ),
                  if (isAuthenticated)
                    ListTile(
                      leading: Icon(Icons.history, color: Colors.white),
                      title: Text(
                        'Historial de Chats',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
                    leading: Icon(Icons.settings, color: Colors.white),
                    title: Text(
                      'Configuración',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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
                      color: Colors.white,
                    ),
                    title: Text(
                      isAuthenticated ? 'Cerrar Sesión' : 'Iniciar Sesión',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (isAuthenticated) {
                        _signOut();
                      } else {
                        _showLoginModal();
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
            top: 50,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 10),
              child: Text(
                'Lumorah es para ti si\na veces necesitas un lugar donde poder estar contigo mismo, con lo que sea que estés sintiendo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.9),
                  fontFamily: 'Lora',
                ),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (_, __) {
                return Container(
                  width: _animation.value,
                  height: _animation.value,
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
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1000),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final sigma = 10 * (1 - animation.value.abs());
                    return ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: child,
                );
              },
              child: Text(
                frases[_fraseIndex],
                key: ValueKey<int>(_fraseIndex),
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontFamily: 'Lora',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // En HomeScreen:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatMessages: [],
                        inputMode: 'keyboard',
                        sessionId: null, // Inicia sin sesión
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.message,
                      size: 30, color: Colors.black54),
                ),
              ),
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
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticulasPainter(_controller.value),
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
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 25; i++) {
      final dx = (size.width * ((i * 17 + progress * 120) % 100) / 100);
      final dy = size.height * ((i * 13 + progress * 90) % 100) / 100;
      final radius = 1.8 + (i % 4);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticulasPainter oldDelegate) => true;
}
