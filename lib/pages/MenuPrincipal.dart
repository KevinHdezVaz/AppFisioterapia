import 'dart:math';
import 'package:LumorahAI/pages/home_page.dart';
import 'package:LumorahAI/pages/screens/SettingsModal.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer(); // Añade esto

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

    _loadStoredLanguage();
    _playStartupSound(); // Añade esta línea
  }

  Future<void> _loadStoredLanguage() async {
    final storedLanguage = await _storageService.getLanguage();
    if (storedLanguage != null && mounted) {
      context.setLocale(Locale(storedLanguage));
    }
  }

  @override
  void dispose() {
    _sunController.dispose();
    _textController.dispose();
    _audioPlayer.dispose(); // Asegúrate de limpiar el reproductor de audio
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

  Future<void> _playStartupSound() async {
    try {
      // Obtener la preferencia de sonido del usuario
      final soundPref = await _storageService.getString('sound_enabled');
      // Si no hay preferencia guardada, se asume true (activado por defecto)
      final soundEnabled = soundPref == null ? true : soundPref == 'true';

      if (soundEnabled) {
        await _audioPlayer.setVolume(0.5); // Ajusta el volumen si es necesario
        await _audioPlayer.play(AssetSource('sounds/inicio.mp3'));
      }
    } catch (e) {
      debugPrint('Error al reproducir sonido de inicio: $e');
      // Opcional: Mostrar un mensaje de error al usuario si lo prefieres
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errorPlayingSound'.tr())),
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => WillPopScope(
          onWillPop: () async => false,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );

      await _authService.logout();

      if (mounted) {
        navigator.pop();
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => Menuprincipal()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) navigator.pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('logout_error'.tr(args: [e.toString()]))),
        );
      }
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

  void _showLanguageSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'selectLanguage'.tr(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildLanguageCard(
                    context,
                    'Español',
                    'es',
                    '🇪🇸',
                    Colors.red[700]!,
                  ),
                  _buildLanguageCard(
                    context,
                    'English',
                    'en',
                    '🇬🇧',
                    Colors.blue[700]!,
                  ),
                  _buildLanguageCard(
                    context,
                    'Français',
                    'fr',
                    '🇫🇷',
                    Colors.blue[600]!,
                  ),
                  _buildLanguageCard(
                    context,
                    'Português',
                    'pt',
                    '🇵🇹',
                    Colors.green[700]!,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context, String languageName,
      String languageCode, String flag, Color color) {
    return GestureDetector(
      onTap: () async {
        await _storageService.saveLanguage(languageCode);
        if (mounted) {
          context.setLocale(Locale(languageCode));
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('languageChanged'.tr(args: [languageName])),
              backgroundColor: color.withOpacity(0.8),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ivoryColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              flag,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(width: 10),
            Text(
              languageName,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SettingsModal(
        onSignOut: () => _signOut(context),
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
                      String headerText = 'helloLumorah'.tr();
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
                      'chat'.tr(),
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
                        'chatHistory'.tr(),
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
                      'changeLanguage'.tr(),
                      style: TextStyle(
                        color: lightTextColor,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showLanguageSelector(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.settings, color: lightTextColor),
                    title: Text(
                      'settings'.tr(),
                      style: TextStyle(
                        color: lightTextColor,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showSettingsModal(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      isAuthenticated ? Icons.logout : Icons.login,
                      color: lightTextColor,
                    ),
                    title: Text(
                      isAuthenticated ? 'logOut'.tr() : 'logIn'.tr(),
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
                  'writeOrSpeak'.tr(),
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
                  'iAmHere'.tr(),
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
                      hintText: 'writeHint'.tr(),
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
