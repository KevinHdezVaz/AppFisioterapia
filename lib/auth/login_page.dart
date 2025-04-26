import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:particles_flutter/particles_engine.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/auth/forget_pass_page.dart';
import 'package:user_auth_crudd10/pages/home_page.dart';
import 'package:user_auth_crudd10/services/settings/theme_data.dart';
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

  // Text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  // Login logic
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
            builder: (context) => const HomeScreen(),
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
      backgroundColor: LumorahColors.primary,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Fondo con partículas
            SizedBox(
              width: size.width,
              height: size.height,
              child: Particles(
                awayRadius: 150,
                particles: ParticleUtils.createParticles(
                  numberOfParticles: 70,
                  color: Colors.white,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(90, 20, 0, 0),
              child: Image.asset('assets/images/grad2.png'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 100, 0),
              child: Image.asset('assets/images/grad1.png'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Center(
                child: Container(
                  height: size.height * 0.8,
                  width: size.width * 0.9,
                  decoration: BoxDecoration(
                    color: LumorahColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: LumorahColors.primaryDark.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                        child: Image.asset(
                          'assets/icons/logoapp.webp',
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "Ingresa tu correo y contraseña o crea una cuenta.",
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: LumorahColors.textLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextField(
                          cursorColor: LumorahColors.primary,
                          controller: _emailController,
                          decoration: InputDecoration(
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
                          ),
                          style: TextStyle(color: LumorahColors.textLight),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextField(
                          cursorColor: LumorahColors.primary,
                          controller: _passwordController,
                          obscureText: isObscure,
                          decoration: InputDecoration(
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
                            labelText: " Contraseña ",
                            labelStyle:
                                TextStyle(color: LumorahColors.primaryDark),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  isObscure = !isObscure;
                                });
                              },
                              icon: Icon(
                                isObscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: LumorahColors.primary,
                              ),
                            ),
                          ),
                          style: TextStyle(color: LumorahColors.textLight),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                setState(() {
                                  isRember = !isRember;
                                });
                              },
                              icon: Icon(
                                isRember
                                    ? Icons.check_box_outline_blank
                                    : Icons.check_box,
                                color: LumorahColors.primary,
                              ),
                            ),
                            Text(
                              'Recordarme',
                              style: TextStyle(
                                  fontSize: 16, color: LumorahColors.textLight),
                            ),
                            const SizedBox(width: 40),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgetPassPage(),
                                  ),
                                );
                              },
                              child: Text(
                                "Olvide contraseña",
                                style: TextStyle(
                                  color: LumorahColors.primaryDark,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  decorationColor: LumorahColors.primaryDark,
                                  decorationThickness: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                      Container(
                        width: size.width * 0.8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LumorahColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: LumorahColors.primaryDark.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 50),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(
                            "Entrar",
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: widget.showLoginPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 50),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          "Crea tu cuenta",
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: LumorahColors.primaryDark,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
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
