// lib/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/features/auth/providers/auth_provider.dart';
import 'package:gasra_monitoring/navigation/main_navigation_page.dart';
import 'package:gasra_monitoring/features/dashboard/ptc_home_page.dart'; // [BARU] Import halaman PTC
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
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.loadUserProfile();

      // [DIUBAH TOTAL] Logika untuk memeriksa role
      if (mounted) {
        if (authProvider.userRole == 'ptc') {
          // Jika role adalah PTC, arahkan ke halaman khusus PTC
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const PtcHomePage()),
          );
        } else {
          // Jika role lain, arahkan ke halaman utama dengan bottom bar
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainNavigationPage()),
          );
        }
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
