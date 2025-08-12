import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/auth/auth_gate_page.dart';
import 'package:gasra_monitoring/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gasra_monitoring/features/auth/providers/auth_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase
import 'firebase_options.dart';
import 'package:gasra_monitoring/core/services/notification_service.dart';

// [PENTING] GlobalKey ini memungkinkan kita navigasi dari mana saja
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi service notifikasi di awal
  await NotificationService().initialize();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // [PENTING] Pasang navigatorKey di sini
      navigatorKey: navigatorKey,
      title: 'GASRA Monitoring',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthGatePage(),
      },
    );
  }
}
