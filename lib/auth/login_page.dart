import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:particles_flutter/particles_engine.dart';
import 'package:user_auth_crudd10/auth/auth_check.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/auth/forget_pass_page.dart';
import 'package:user_auth_crudd10/pages/bottom_nav.dart';
import 'package:user_auth_crudd10/pages/home_page.dart';
import 'package:user_auth_crudd10/utils/ParticleUtils.dart';
import 'package:user_auth_crudd10/utils/colors.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const LoginPage({super.key, required this.showLoginPage});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isRember = false;
  bool isObscure = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  Future<void> signIn() async {
    if (!validateLogin()) return;

    try {
      showDialog(
        context: context,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: LumorahColors.primary,
          ),
        ),
      );

      final success = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      Navigator.pop(context);

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const BottomNavBar(),
          ),
        );
      } else {
        showErrorSnackBar('Credenciales inválidas');
      }
    } catch (e) {
      Navigator.pop(context);
      showErrorSnackBar(e.toString());
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool validateLogin() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showErrorSnackBar("Por favor complete todos los campos");
      return false;
    }

    if (!_emailController.text.contains('@')) {
      showErrorSnackBar("Correo electrónico inválido");
      return false;
    }

    if (_passwordController.text.length < 6) {
      showErrorSnackBar("La contraseña debe tener al menos 6 caracteres");
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

    return Scaffold(
      backgroundColor: LumorahColors.lightBackground,
      body: Stack(
        children: [
          // Fondo con partículas (opcional)
          SizedBox(
            width: size.width,
            height: size.height,
            child: Particles(
              awayRadius: 150,
              particles: ParticleUtils.createParticles(
                numberOfParticles: 70,
                color: LumorahColors.accent,
                maxSize: 5.0,
                maxVelocity: 50.0,
              ),
              height: size.height,
              width: size.width,
              onTapAnimation: true,
              awayAnimationDuration: const Duration(milliseconds: 600),
              awayAnimationCurve: Curves.easeIn,
              enableHover: true,
              hoverRadius: 90,
              connectDots: false,
            ),
          ),

          SingleChildScrollView(
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(top: 80),
                width: size.width * 0.9,
                decoration: BoxDecoration(
                  color: LumorahColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Por esto:
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                      child: SizedBox(
                        // Añade este SizedBox
                        width: 150,
                        height: 150,
                        child: Lottie.asset(
                          'assets/images/circuloIA.json',
                          fit: BoxFit.contain,
                          repeat: true,
                          animate: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Bienvenido a Lumorah",
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: LumorahColors.textOnPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Estoy aquí para acompañarte",
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: LumorahColors.textOnPrimary.withOpacity(0.9),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        cursorColor: LumorahColors.primary,
                        controller: _emailController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: LumorahColors.primary.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: LumorahColors.primary,
                              width: 1.5,
                            ),
                          ),
                          labelText: "Correo",
                          labelStyle:
                              TextStyle(color: LumorahColors.primaryDark),
                          floatingLabelStyle: TextStyle(
                            color: LumorahColors.primaryDark,
                            fontSize: 14,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 20, horizontal: 16),
                          prefixIcon:
                              Icon(Icons.email, color: LumorahColors.primary),
                        ),
                        style: TextStyle(color: LumorahColors.textLight),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        cursorColor: LumorahColors.primary,
                        controller: _passwordController,
                        obscureText: isObscure,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: LumorahColors.primary.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: LumorahColors.primary,
                              width: 1.5,
                            ),
                          ),
                          labelText: "Contraseña",
                          labelStyle:
                              TextStyle(color: LumorahColors.primaryDark),
                          floatingLabelStyle: TextStyle(
                            color: LumorahColors.primaryDark,
                            fontSize: 14,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 20, horizontal: 16),
                          prefixIcon:
                              Icon(Icons.lock, color: LumorahColors.primary),
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
                        ),
                        style: TextStyle(color: LumorahColors.textLight),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: isRember,
                                onChanged: (value) =>
                                    setState(() => isRember = value ?? false),
                                activeColor: LumorahColors.primary,
                              ),
                              Text(
                                "Recordarme",
                                style: TextStyle(
                                  color: LumorahColors.textOnPrimary,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgetPassPage(),
                              ),
                            ),
                            child: Text(
                              "¿Olvidaste tu contraseña?",
                              style: TextStyle(
                                color: LumorahColors.textOnPrimary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LumorahColors.primaryDarker,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Entrar",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: widget.showLoginPage,
                      child: RichText(
                        text: TextSpan(
                          text: "¿No tienes una cuenta? ",
                          style: TextStyle(
                            color: LumorahColors.textOnPrimary,
                          ),
                          children: [
                            TextSpan(
                              text: "Regístrate",
                              style: TextStyle(
                                color: LumorahColors.textOnPrimary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
