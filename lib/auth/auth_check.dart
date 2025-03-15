import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/auth/auth_page_check.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/pages/Fisioterapeuta/PhysiotherapistDashboard.dart';
import 'package:user_auth_crudd10/pages/bottom_nav.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';

class AuthCheckMain extends StatelessWidget {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _storageService.getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _authService.getProfile(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (profileSnapshot.hasData) {
                final user = profileSnapshot.data!;
                final role = user['role'];

                switch (role) {
                  case 'physiotherapist':
                    return PhysiotherapistDashboard();
                  case 'patient':
                    return BottomNavBar(); // Usamos BottomNavBar para pacientes
                  default:
                    _authService.logout();
                    return AuthPageCheck();
                }
              } else {
                _authService.logout();
                return AuthPageCheck();
              }
            },
          );
        }

        return AuthPageCheck();
      },
    );
  }
}
