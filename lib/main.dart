import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart'; // For intl package
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Importa esto

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

  // 1. Carga variables de entorno PRIMERO
  await dotenv.load(fileName: '.env');

  // 2. Manejo seguro de Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      await Firebase.app(); // Usa la instancia existente
    }
  } catch (e) {
    debugPrint("Error inicializando Firebase: $e");
    rethrow;
  }

  // 3. Inicializa notificaciones
  await FirebaseApi().initNotifications();

  // 4. Ejecuta la app
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
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
        localizationsDelegates: const [
          AppLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(),
      ),
    );
  }
}
