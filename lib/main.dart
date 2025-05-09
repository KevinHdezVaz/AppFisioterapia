import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    print('Cargando .env...');
    await dotenv.load(fileName: '.env');
    print('Variables: ${dotenv.env['ANDROID_API_KEY']}');
    print('Inicializando Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Configurando notificaciones...');
    await FirebaseApi().initNotifications();
  } catch (e, stackTrace) {
    debugPrint('Error durante la inicialización: $e');
    debugPrint('StackTrace: $stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Error al iniciar: $e')),
        ),
      ),
    );
    return;
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );

  FlutterNativeSplash.remove();
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
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('es'),
        ],
        home:   HomeScreen(), // o AuthCheck() según tu lógica de login
      ),
    );
  }
}
