import 'package:LumorahAI/auth/auth_service.dart';
import 'package:LumorahAI/pages/screens/chats/ChatScreen.dart';
import 'package:LumorahAI/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class LoginModal extends StatefulWidget {
  final VoidCallback? showRegisterPage;
  final String? inputMode;

  const LoginModal({
    super.key,
    this.showRegisterPage,
    this.inputMode,
  });

  @override
  State<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends State<LoginModal> with TickerProviderStateMixin {
  bool isRember = false;
  bool isObscure = true;
  bool _showEmailFields = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final _scrollController = ScrollController(); // Nuevo ScrollController

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    _scrollController.dispose(); // Dispose del ScrollController
    super.dispose();
  }

  Future<void> signIn() async {
    if (!validateLogin()) return;

    try {
      showDialog(
        context: context,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      Navigator.pop(context); // Close loading dialog

      if (!mounted) return;

      if (success) {
        Navigator.pop(context); // Close LoginModal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              initialMessages: [],
              inputMode: widget.inputMode ?? 'keyboard',
            ),
          ),
        );
      } else {
        showErrorToast('invalidCredentials'.tr());
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      showErrorToast('generalError'.tr(args: [e.toString()]));
    }
  }

  bool validateLogin() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showErrorToast('fillAllFields'.tr());
      return false;
    }

    if (!_emailController.text.contains('@')) {
      showErrorToast('invalidEmail'.tr());
      return false;
    }

    if (_passwordController.text.length < 6) {
      showErrorToast('passwordTooShort'.tr());
      return false;
    }

    return true;
  }

  void showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: LumorahColors.error,
      textColor: Colors.white,
      fontSize: 16.0,
      webPosition: "center",
      webBgColor: LumorahColors.error.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: size.height * 0.8, // Limitar la altura máxima del diálogo
          maxWidth: size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Custom AppBar
            Container(
              width: size.width * 0.9,
              decoration: const BoxDecoration(
                color: Color(0xFF4BB6A8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48),
                    Text(
                      'login'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),

            // Main content con scroll
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController, // Asignar el ScrollController
                child: Container(
                  width: size.width * 0.9,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4BB6A8),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.only(bottom: 20.0), // Espacio adicional para el teclado
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'welcomeToLumorah'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: LumorahColors.textOnPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'iAmHereToAccompany'.tr(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            color: LumorahColors.textOnPrimary.withOpacity(0.9),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Botones de inicio de sesión
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            OutlinedButton(
                              onPressed: () async {
                                try {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Center(
                                      child: CircularProgressIndicator(
                                        color: LumorahColors.primary,
                                      ),
                                    ),
                                  );

                                  final success = await _authService.signInWithGoogle();

                                  if (!mounted) return;
                                  Navigator.pop(context); // Close loading

                                  if (success) {
                                    Navigator.pop(context); // Close LoginModal
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          initialMessages: [],
                                          inputMode: widget.inputMode ?? 'keyboard',
                                        ),
                                      ),
                                    );
                                  } else {
                                    showErrorToast('googleSignInError'.tr());
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  Navigator.pop(context); // Close loading
                                  showErrorToast('generalError'.tr(args: [e.toString()]));
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: LumorahColors.textOnPrimary,
                                side: BorderSide(color: LumorahColors.textOnPrimary),
                                minimumSize: const Size(200, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/google.png',
                                    height: 24,
                                    width: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('continueWithGoogle'.tr()),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () async {
                                try {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Center(
                                      child: CircularProgressIndicator(
                                        color: LumorahColors.primary,
                                      ),
                                    ),
                                  );

                                  final success = await _authService.signInWithFacebook();

                                  if (!mounted) return;
                                  Navigator.pop(context); // Close loading

                                  if (success) {
                                    Navigator.pop(context); // Close LoginModal
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          initialMessages: [],
                                          inputMode: widget.inputMode ?? 'keyboard',
                                        ),
                                      ),
                                    );
                                  } else {
                                    showErrorToast('facebookSignInError'.tr());
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  Navigator.pop(context); // Close loading
                                  showErrorToast('generalError'.tr(args: [e.toString()]));
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: LumorahColors.textOnPrimary,
                                side: BorderSide(color: LumorahColors.textOnPrimary),
                                minimumSize: const Size(200, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/facebook.png',
                                    height: 24,
                                    width: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('continueWithFacebook'.tr()),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _showEmailFields = true;
                                });
                                // Desplazar hacia abajo después de mostrar los campos
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (_scrollController.hasClients) {
                                    _scrollController.animateTo(
                                      _scrollController.position.maxScrollExtent,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: LumorahColors.textOnPrimary,
                                side: BorderSide(color: LumorahColors.textOnPrimary),
                                minimumSize: const Size(200, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.email,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('continueWithEmail'.tr()),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Campos de correo y contraseña
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 300),
                        crossFadeState: _showEmailFields
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              TextField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  labelText: 'email'.tr(),
                                  labelStyle: const TextStyle(color: LumorahColors.primaryDarker),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.8),
                                  prefixIcon: const Icon(Icons.email, color: LumorahColors.primary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: LumorahColors.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                obscureText: isObscure,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  labelText: 'password'.tr(),
                                  labelStyle: const TextStyle(color: LumorahColors.primaryDarker),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.8),
                                  prefixIcon: const Icon(Icons.lock, color: LumorahColors.primary),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      isObscure ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.black,
                                    ),
                                    onPressed: () => setState(() => isObscure = !isObscure),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: LumorahColors.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: LumorahColors.primaryDarker,
                                  minimumSize: const Size(200, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'enter'.tr(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        secondChild: const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 20),
                      if (widget.showRegisterPage != null)
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.showRegisterPage!();
                          },
                          child: Text(
                            'noAccount'.tr(),
                            style: TextStyle(color: LumorahColors.primaryDarker),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}