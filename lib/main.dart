import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa easy_localization
  await EasyLocalization.ensureInitialized();

  // 1. Carga variables de entorno
  await dotenv.load(fileName: '.env');

  // 2. Manejo seguro de Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      await Firebase.app();
    }
  } catch (e) {
    debugPrint("Error inicializando Firebase: $e");
    rethrow;
  }

  // 3. Inicializa notificaciones
  await FirebaseApi().initNotifications();

  // 4. Obtén el idioma inicial
  final prefs = await SharedPreferences.getInstance();
  final savedLanguageCode = prefs.getString('languageCode');
  Locale startLocale;

  // Lista de idiomas soportados
  const supportedLocales = [Locale('en', ''), Locale('es', '')];

  // Si hay un idioma guardado, úsalo
  if (savedLanguageCode != null) {
    startLocale = Locale(savedLanguageCode, '');
  } else {
    // Si no hay idioma guardado, usa el idioma del dispositivo
    final deviceLocale = WidgetsBinding.instance.window.locale;
    // Busca si el idioma del dispositivo está soportado
    final matchingLocale = supportedLocales.firstWhere(
      (locale) => locale.languageCode == deviceLocale.languageCode,
      orElse: () => const Locale('en', ''), // Fallback si no está soportado
    );
    startLocale = matchingLocale;
    // Guarda el idioma del dispositivo como preferencia inicial
    await prefs.setString('languageCode', startLocale.languageCode);
  }

  // 5. Ejecuta la app con easy_localization
  runApp(
    EasyLocalization(
      supportedLocales: supportedLocales,
      path: 'assets/translations',
      fallbackLocale: const Locale('en', ''),
      startLocale: startLocale, // Usa el idioma inicial detectado
      child: ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
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
