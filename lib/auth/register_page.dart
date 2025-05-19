import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:particles_flutter/particles_engine.dart';
import 'package:LumorahAI/auth/auth_service.dart';
import 'package:LumorahAI/pages/screens/chats/ChatScreen.dart';
import 'package:LumorahAI/utils/ParticleUtils.dart';
import 'package:LumorahAI/utils/colors.dart';
import 'package:easy_localization/easy_localization.dart';

class RegisterModal extends StatefulWidget {
  final VoidCallback? showLoginPage;
  final String? inputMode;

  const RegisterModal({
    super.key,
    this.showLoginPage,
    this.inputMode,
  });

  @override
  State<RegisterModal> createState() => _RegisterModalState();
}

class _RegisterModalState extends State<RegisterModal> {
  bool isPasswordObscure = true;
  bool isConfirmPasswordObscure = true;
  bool _showEmailFields = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    if (!validateRegister()) return;
    try {
      showDialog(
        context: context,
        builder: (_) => Center(
          child: CircularProgressIndicator(
            color: LumorahColors.primary,
          ),
        ),
      );

      final success = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      if (success) {
        Navigator.pop(context); // Close RegisterModal
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
        showErrorToast('registrationFailed'.tr());
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog
      showErrorToast('generalError'.tr(args: [e.toString()]));
    }
  }

  bool validateRegister() {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
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

    if (_passwordController.text != _confirmPasswordController.text) {
      showErrorToast('passwordsMismatch'.tr());
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Particle background
          SizedBox(
            width: size.width * 0.9,
            height: 650,
            child: Particles(
              awayRadius: 150,
              particles: ParticleUtils.createParticles(
                numberOfParticles: 70,
                color: LumorahColors.accent,
                maxSize: 5.0,
                maxVelocity: 50.0,
              ),
              height: 650,
              width: size.width * 0.9,
              onTapAnimation: true,
              awayAnimationDuration: const Duration(milliseconds: 600),
              awayAnimationCurve: Curves.easeIn,
              enableHover: true,
              hoverRadius: 90,
              connectDots: false,
            ),
          ),

          // Main content with AppBar
          Column(
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'register'.tr(),
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

              // Rest of the form
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
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
                        Text(
                          'startYourJourney'.tr(),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: LumorahColors.textOnPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Botones de registro (Google, Facebook, Email)
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

                                    final success =
                                        await _authService.signInWithGoogle();

                                    if (!mounted) return;
                                    Navigator.pop(context); // Cerrar loading

                                    if (success) {
                                      Navigator.pop(
                                          context); // Cerrar RegisterModal
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            initialMessages: [],
                                            inputMode:
                                                widget.inputMode ?? 'keyboard',
                                          ),
                                        ),
                                      );
                                    } else {
                                      showErrorToast('googleSignInError'.tr());
                                    }
                                  } catch (e) {
                                    if (!mounted) return;
                                    Navigator.pop(context); // Cerrar loading
                                    showErrorToast('generalError'
                                        .tr(args: [e.toString()]));
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: LumorahColors.textOnPrimary,
                                  side: BorderSide(
                                      color: LumorahColors.textOnPrimary),
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
                                      'continueWithGoogle'.tr(),
                                    ),
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

                                    final success =
                                        await _authService.signInWithFacebook();

                                    if (!mounted) return;
                                    Navigator.pop(context); // Cerrar loading

                                    if (success) {
                                      Navigator.pop(
                                          context); // Cerrar RegisterModal
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            initialMessages: [],
                                            inputMode:
                                                widget.inputMode ?? 'keyboard',
                                          ),
                                        ),
                                      );
                                    } else {
                                      showErrorToast(
                                          'facebookSignInError'.tr());
                                    }
                                  } catch (e) {
                                    if (!mounted) return;
                                    Navigator.pop(context); // Cerrar loading
                                    showErrorToast('generalError'
                                        .tr(args: [e.toString()]));
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: LumorahColors.textOnPrimary,
                                  side: BorderSide(
                                      color: LumorahColors.textOnPrimary),
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
                                    Text(
                                      'continueWithFacebook'.tr(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _showEmailFields = true;
                                    _scrollToBottom();
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: LumorahColors.textOnPrimary,
                                  side: BorderSide(
                                      color: LumorahColors.textOnPrimary),
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
                                    Text(
                                      'continueWithEmail'.tr(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Campos de registro (visibles solo si _showEmailFields es true)
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
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'name'.tr(),
                                    labelStyle: const TextStyle(
                                        color: LumorahColors.primaryDarker),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.8),
                                    prefixIcon: const Icon(Icons.person,
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
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'email'.tr(),
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
                                  obscureText: isPasswordObscure,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'password'.tr(),
                                    labelStyle: const TextStyle(
                                        color: LumorahColors.primaryDarker),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.8),
                                    prefixIcon: const Icon(Icons.lock,
                                        color: LumorahColors.primary),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        isPasswordObscure
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: LumorahColors.primary,
                                      ),
                                      onPressed: () => setState(() =>
                                          isPasswordObscure =
                                              !isPasswordObscure),
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
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: isConfirmPasswordObscure,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    labelText: 'confirmPassword'.tr(),
                                    labelStyle: const TextStyle(
                                        color: LumorahColors.primaryDarker),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.8),
                                    prefixIcon: const Icon(Icons.lock,
                                        color: LumorahColors.primary),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        isConfirmPasswordObscure
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: LumorahColors.primary,
                                      ),
                                      onPressed: () => setState(() =>
                                          isConfirmPasswordObscure =
                                              !isConfirmPasswordObscure),
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
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: signUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        LumorahColors.primaryDarker,
                                    minimumSize: const Size(200, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'createAccount'.tr(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          secondChild: const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 20),
                        if (widget.showLoginPage != null)
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.showLoginPage!();
                            },
                            child: Text(
                              'alreadyHaveAccount'.tr(),
                              style:
                                  TextStyle(color: LumorahColors.primaryDarker),
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
        ],
      ),
    );
  }
}
