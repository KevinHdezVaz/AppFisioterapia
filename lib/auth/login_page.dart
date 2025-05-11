import 'package:LumorahAI/auth/auth_service.dart';
import 'package:LumorahAI/pages/screens/chats/ChatScreen.dart';
import 'package:LumorahAI/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart'; // Nuevo import

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

class _LoginModalState extends State<LoginModal> {
  bool isRember = false;
  bool isObscure = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
      gravity: ToastGravity.BOTTOM, // Muestra en la parte superior
      timeInSecForIosWeb: 3,
      backgroundColor: LumorahColors.error,
      textColor: Colors.white,
      fontSize: 16.0,
      webPosition: "center", // Para versión web
      webBgColor: LumorahColors.error.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Custom AppBar
          Container(
            width: size.width * 0.9,
            decoration: BoxDecoration(
              color: const Color(0xFF4BB6A8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  Text(
                    'login'.tr(), // Traducción
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

          // Main content
          SingleChildScrollView(
            child: Container(
              width: size.width * 0.9,
              decoration: BoxDecoration(
                color: const Color(0xFF4BB6A8),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber.withOpacity(0.3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.5),
                            blurRadius: 50,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'welcomeToLumorah'.tr(), // Traducción
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
                      'iAmHereToAccompany'.tr(), // Traducción
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: LumorahColors.textOnPrimary.withOpacity(0.9),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'email'.tr(), // Traducción
                            labelStyle: const TextStyle(
                                color: LumorahColors.primaryDarker),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            prefixIcon: const Icon(Icons.email,
                                color: LumorahColors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: LumorahColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: isObscure,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'password'.tr(), // Traducción
                            labelStyle: const TextStyle(
                                color: LumorahColors.primaryDarker),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            prefixIcon: const Icon(Icons.lock,
                                color: LumorahColors.primary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isObscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.black,
                              ),
                              onPressed: () =>
                                  setState(() => isObscure = !isObscure),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: LumorahColors.primary),
                            ),
                          ),
                        ),
                      ],
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
                      'enter'.tr(), // Traducción
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (widget.showRegisterPage != null)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.showRegisterPage!();
                      },
                      child: Text(
                        'noAccount'.tr(), // Traducción
                        style: TextStyle(color: LumorahColors.primaryDarker),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    'orSignInWith'.tr(), // Traducción
                    style: TextStyle(
                      color: LumorahColors.textOnPrimary,
                      fontSize: 14,
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

                        final success = await _authService.signInWithGoogle();

                        if (!mounted) return;
                        Navigator.pop(context); // Cerrar loading

                        if (success) {
                          Navigator.pop(context); // Cerrar LoginModal
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
                        Navigator.pop(context); // Cerrar loading
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
                        Text(
                          'continueWithGoogle'.tr(), // Traducción
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
