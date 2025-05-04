import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:particles_flutter/particles_engine.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/pages/screens/chats/ChatScreen.dart';
import 'package:user_auth_crudd10/utils/ParticleUtils.dart';
import 'package:user_auth_crudd10/utils/colors.dart';

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

class _RegisterModalState extends State<RegisterModal>
    with SingleTickerProviderStateMixin {
  bool isObscure = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 80, end: 120).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
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

      // Check if the widget is still mounted before proceeding
      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      if (success) {
        Navigator.pop(context); // Close RegisterModal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatMessages: [],
              inputMode: widget.inputMode ?? 'keyboard',
            ),
          ),
        );
      } else {
        showErrorSnackBar("No se pudo completar el registro.");
      }
    } catch (e) {
      // Check if the widget is still mounted before proceeding
      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog
      showErrorSnackBar(e.toString());
    }
  }

  bool validateRegister() {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      showErrorSnackBar("Por favor complete todos los campos obligatorios");
      return false;
    }

    if (!_emailController.text.contains('@')) {
      showErrorSnackBar("Correo electrónico inválido");
      return false;
    }

    if (_nameController.text.contains(RegExp(r'[^a-zA-Z\s]'))) {
      showErrorSnackBar("El nombre solo debe contener letras");
      return false;
    }

    if (_passwordController.text.length < 6) {
      showErrorSnackBar("La contraseña debe tener al menos 6 caracteres");
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      showErrorSnackBar("Las contraseñas no coinciden");
      return false;
    }

    return true;
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: LumorahColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
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
                      const Text(
                        'Registro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Close button
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),

              // Rest of the form
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
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (_, __) {
                            return Container(
                              width: _animation.value,
                              height: _animation.value,
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
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Comienza tu viaje con Lumorah",
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
                          "Estoy aquí para acompañarte en cada paso",
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
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: "Nombre",
                                labelStyle: TextStyle(
                                    color: LumorahColors.primaryDarker),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.8),
                                prefixIcon: Icon(Icons.person,
                                    color: LumorahColors.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: LumorahColors.primary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: "Correo",
                                labelStyle: TextStyle(
                                    color: LumorahColors.primaryDarker),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.8),
                                prefixIcon: Icon(Icons.email,
                                    color: LumorahColors.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: LumorahColors.primary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passwordController,
                              obscureText: isObscure,
                              decoration: InputDecoration(
                                labelText: "Contraseña",
                                labelStyle: TextStyle(
                                    color: LumorahColors.primaryDarker),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.8),
                                prefixIcon: Icon(Icons.lock,
                                    color: LumorahColors.primary),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isObscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: LumorahColors.primary,
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
                                  borderSide:
                                      BorderSide(color: LumorahColors.primary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: isObscure,
                              decoration: InputDecoration(
                                labelText: "Confirmar contraseña",
                                labelStyle: TextStyle(
                                    color: LumorahColors.primaryDarker),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.8),
                                prefixIcon: Icon(Icons.lock,
                                    color: LumorahColors.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: LumorahColors.primary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LumorahColors.primaryDarker,
                          minimumSize: const Size(200, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Crear cuenta",
                            style: TextStyle(color: Colors.white)),
                      ),
                      if (widget.showLoginPage != null)
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.showLoginPage!();
                          },
                          child: Text(
                            "¿Ya tienes una cuenta? Inicia sesión",
                            style:
                                TextStyle(color: LumorahColors.primaryDarker),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
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
