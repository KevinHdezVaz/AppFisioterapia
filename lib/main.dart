import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:LumorahAI/auth/auth_check.dart';
import 'package:LumorahAI/auth/auth_service.dart';
import 'package:LumorahAI/onscreen/onboardingWrapper.dart';
import 'package:LumorahAI/pages/Mercadopago/payment_service.dart';
import 'package:LumorahAI/pages/bottom_nav.dart';
import 'package:LumorahAI/pages/home_page.dart';
 import 'package:LumorahAI/services/functions/firebase_notification.dart';
import 'package:LumorahAI/services/notifcationService.dart';
import 'package:LumorahAI/services/providers/storage_ans_provider.dart';
import 'package:LumorahAI/services/providers/storage_provider.dart';
import 'package:LumorahAI/services/settings/theme_data.dart';
import 'package:LumorahAI/services/settings/theme_provider.dart';
import 'package:LumorahAI/utils/constantes.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>(); // <-- Añade esto
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi().initNotifications();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(), // Eliminamos la dependencia de isviewed
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => StorageProvider()),
        ChangeNotifierProvider(create: (context) => StorageAnsProvider()),
        Provider<AuthService>(create: (_) => AuthService()),
         Provider<PaymentService>(create: (_) => PaymentService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        themeMode: themeProvider.currentTheme,
        theme: lightTheme,
        darkTheme: darkTheme,
        home: HomeScreen(),
      ),
    );
  }
}
