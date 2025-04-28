import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:particles_flutter/particles_engine.dart';
import 'package:user_auth_crudd10/auth/auth_check.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/auth/login_page.dart';
import 'package:user_auth_crudd10/utils/ParticleUtils.dart';
import 'package:user_auth_crudd10/utils/colors.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const RegisterPage({super.key, required this.showLoginPage});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool isObscure = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

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

      Navigator.pop(context);

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthCheckMain()),
        );
      } else {
        showErrorSnackBar("No se pudo completar el registro.");
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
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

    return WillPopScope(
      onWillPop: () async {
        widget.showLoginPage();
        return false; // Evita el pop predeterminado
      },
      child: Scaffold(
        backgroundColor: LumorahColors.lightBackground,
        appBar: AppBar(
          backgroundColor: LumorahColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: LumorahColors.textOnPrimary),
            onPressed: widget.showLoginPage,
          ),
          title: Text(
            "Registro",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: LumorahColors.textOnPrimary,
            ),
          ),
        ),
        body: Stack(
          children: [
            // Fondo con partículas
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
                  margin: const EdgeInsets.only(top: 20),
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
                      const SizedBox(height: 20),
                      Text(
                        "Comienza tu viaje con Lumorah",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: LumorahColors.textOnPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "Estoy aquí para acompañarte en cada paso",
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            color: LumorahColors.textOnPrimary.withOpacity(0.9),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          cursorColor: LumorahColors.primary,
                          controller: _nameController,
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
                            labelText: "Nombre",
                            labelStyle:
                                TextStyle(color: LumorahColors.primaryDark),
                            floatingLabelStyle: TextStyle(
                              color: LumorahColors.primaryDark,
                              fontSize: 14,
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 20, horizontal: 16),
                            prefixIcon: Icon(Icons.person,
                                color: LumorahColors.primary),
                          ),
                          style: TextStyle(color: LumorahColors.textLight),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          cursorColor: LumorahColors.primary,
                          controller: _confirmPasswordController,
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
                            labelText: "Confirmar contraseña",
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
                          ),
                          style: TextStyle(color: LumorahColors.textLight),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LumorahColors.primaryDarker,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "Crear cuenta",
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
                            text: "¿Ya tienes una cuenta? ",
                            style: TextStyle(
                              color: LumorahColors.textOnPrimary,
                            ),
                            children: [
                              TextSpan(
                                text: "Inicia sesión",
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
      ),
    );
  }
}
