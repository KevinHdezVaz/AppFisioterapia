import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/auth/login_page.dart';
import 'package:user_auth_crudd10/pages/screens/UpdateProfileScreen.dart';
import 'package:user_auth_crudd10/pages/WalletScreen.dart';
import 'package:user_auth_crudd10/pages/screens/bookin/booking_screen.dart';
import 'package:user_auth_crudd10/utils/colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  // Mock user data for visual purposes
  final Map<String, dynamic> userData = {
    'name': 'Juan Pérez',
    'email': 'juan.perez@example.com',
    'is_verified': true,
    'profile_image': null, // No network image for static UI
  };

  Future<void> _signOut() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: LumorahColors.primary,
          ),
        ),
      );

      await _authService.logout();

      if (!mounted) return;

      // Cerrar el diálogo de carga
      Navigator.pop(context);

      // Navegar a LoginPage reemplazando toda la pila de navegación
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(
            showLoginPage: () {
              // Esta función se usa para alternar entre login/register
              // Asegúrate de pasar la implementación correcta
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(showLoginPage: () {}),
                ),
              );
            },
          ),
        ),
        (route) => false, // Elimina todas las rutas anteriores
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar el loading si hay error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: ${e.toString()}'),
          backgroundColor: LumorahColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        backgroundColor: LumorahColors.lightBackground,
        appBar: AppBar(
          title: Text('Perfil', style: TextStyle(color: Colors.white)),
          backgroundColor: LumorahColors.primary,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: null,
        ),
        body: Column(
          children: [
            ProfilePic(userData: userData),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LumorahColors.primaryGradient,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.white, size: 24),
                            const SizedBox(width: 20),
                            Text(
                              userData['name'] ?? '',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (userData['is_verified'] == true)
                              const SizedBox(width: 8),
                            if (userData['is_verified'] == true)
                              Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 30,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.email, color: Colors.white, size: 24),
                            const SizedBox(width: 20),
                            Text(
                              userData['email'] ?? '',
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            TabBar(
              tabs: [
                Tab(
                    child: Text('OPCIONES',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w600))),
              ],
              indicatorColor: LumorahColors.primary,
              labelColor: LumorahColors.primary,
              unselectedLabelColor: LumorahColors.primary.withOpacity(0.5),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            icon: Icons.person,
                            title: 'Editar Perfil',
                            subtitle: 'Datos de usuario',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        UpdateProfileScreen())),
                          ),
                          _buildMenuItem(
                            icon: Icons.monetization_on,
                            title: 'Monedero',
                            subtitle: 'Ver mi Monedero',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => WalletScreen())),
                          ),
                          _buildMenuItem(
                            icon: Icons.sports_soccer,
                            title: 'Mis Reservaciones',
                            subtitle: 'Ver Reservaciones',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => BookingScreen())),
                          ),
                          const SizedBox(height: 20),
                          // Botón de Cerrar Sesión
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: LumorahColors.error,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  _showLogoutConfirmationDialog();
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.logout, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Cerrar Sesión',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Cerrar Sesión',
            style: GoogleFonts.inter(
              color: LumorahColors.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '¿Estás seguro que deseas cerrar tu sesión?',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(color: LumorahColors.primary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _signOut();
              },
              child: Text(
                'Cerrar Sesión',
                style: GoogleFonts.inter(color: LumorahColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int count = 0,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: LumorahColors.primary.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1))
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: LumorahColors.primaryDark),
            if (count > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: LumorahColors.primary, shape: BoxShape.circle),
                  constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Center(
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
            color: LumorahColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
            fontSize: 14, color: LumorahColors.primary.withOpacity(0.7)),
      ),
      trailing: Icon(Icons.chevron_right, color: LumorahColors.primary),
      onTap: onTap,
    );
  }
}

class ProfilePic extends StatelessWidget {
  final Map<String, dynamic>? userData;
  const ProfilePic({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 115,
        width: 115,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: LumorahColors.primaryLight,
              backgroundImage: const AssetImage('assets/icons/jugadore.png'),
            ),
          ],
        ),
      ),
    );
  }
}
