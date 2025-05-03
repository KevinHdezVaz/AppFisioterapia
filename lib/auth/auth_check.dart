import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/auth/auth_page_check.dart';
import 'package:user_auth_crudd10/pages/bottom_nav.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';

/*
class AuthCheckMain extends StatelessWidget {
  const AuthCheckMain({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: StorageService().getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snapshot.data;
        if (token != null && token.isNotEmpty) {
          return const BottomNavBar();
        }

        //return const AuthPageCheck();
      },
    );
  }
}
*/
