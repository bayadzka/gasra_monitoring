// lib/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/features/auth/providers/auth_provider.dart';
import 'package:gasra_monitoring/navigation/main_navigation_page.dart'; // [BARU] Import halaman navigasi baru
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(
        const Duration(milliseconds: 1500)); // Beri sedikit jeda
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      await context.read<AuthProvider>().loadUserProfile();
      if (mounted) {
        // [FIX] Arahkan ke MainNavigationPage, bukan '/home'
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationPage()),
        );
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Anda bisa tambahkan logo di sini jika mau
            // Image.asset('assets/images/logo.png', height: 120),
            SizedBox(height: 20),
            Text(
              "Fleet Monitoring",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004B87),
              ),
            ),
            SizedBox(height: 10),
            CircularProgressIndicator(
              color: Color(0xFF004B87),
            ),
          ],
        ),
      ),
    );
  }
}
