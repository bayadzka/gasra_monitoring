import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/auth/auth_gate_page.dart';
import 'package:gasra_monitoring/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gasra_monitoring/features/dashboard/home_page.dart';
import 'package:provider/provider.dart';
import 'package:gasra_monitoring/features/auth/providers/auth_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase
import 'firebase_options.dart';
import 'package:gasra_monitoring/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url:
        'https://lyyttxtfffyzfcifcldf.supabase.co/', // Ganti dengan URL Supabase kamu
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5eXR0eHRmZmZ5emZjaWZjbGRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNjIwMTcsImV4cCI6MjA2ODgzODAxN30.oCzbljhK0T1yNDu4iTRjIAkArKbqYhGWP9chNyS-lqo', // Ganti dengan anon key kamu
  );
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().initialize();
  runApp(
    MultiProvider(
      providers: [
        // [DIUBAH] AuthProvider ditambahkan di sini
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
      title: 'GASRA Monitoring',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthGatePage(), // Ganti '/login'
        '/home': (context) => const HomePage(),
      },
    );
  }
}
