// lib/features/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/features/auth/providers/auth_provider.dart';
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
    // Tunggu frame pertama selesai di-build
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // Jika ada sesi, muat profil pengguna
      await context.read<AuthProvider>().loadUserProfile();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      // Jika tidak ada sesi, arahkan ke halaman gerbang otentikasi
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
            // Ganti dengan logo Anda jika path berbeda
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
