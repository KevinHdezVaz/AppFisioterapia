import 'dart:async';
import 'package:LumorahAI/pages/MenuPrincipal.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:LumorahAI/auth/auth_check.dart';
import 'package:LumorahAI/auth/auth_service.dart';
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
  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: '.env');

try {
  // Verifica si la app DEFAULT ya existe
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    // Si ya existe, obtén la instancia existente
    Firebase.app();
  }
} catch (e) {
  debugPrint("Error inicializando Firebase: $e");
}

  await FirebaseApi().initNotifications();

  final prefs = await SharedPreferences.getInstance();
  const defaultLanguage = 'es'; // Español como idioma base

  // 1. Verifica si ya hay un idioma guardado
  final savedLanguageCode = prefs.getString('languageCode');

  // 2. Determina el locale inicial
  Locale startLocale;

  if (savedLanguageCode != null) {
    startLocale = Locale(savedLanguageCode);
  } else {
    final deviceLocale = WidgetsBinding.instance.window.locale;

    // Usa español si el dispositivo está en español, de lo contrario usa español como predeterminado
    startLocale =
        deviceLocale.languageCode == 'es' ? deviceLocale : const Locale('es');

    // Guarda la preferencia
    await prefs.setString('languageCode', startLocale.languageCode);
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
        Locale('fr'), // French
        Locale('pt'), // Portuguese
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('es'), // Fallback en español
      startLocale: startLocale,
      useOnlyLangCode: true, // Ignora códigos de país como MX, CO, AR
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
  bool _onboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    });
  }

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
        localizationsDelegates: [
          ...context.localizationDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        themeMode: themeProvider.currentTheme,
        theme: lightTheme,
        darkTheme: darkTheme,
        home: _onboardingCompleted ? Menuprincipal() : HomeScreen(),
      ),
    );
  }
}