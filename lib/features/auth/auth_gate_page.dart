// lib/features/auth/auth_gate_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/auth/login_page.dart';
import 'package:gasra_monitoring/features/auth/register_page.dart';

class AuthGatePage extends StatelessWidget {
  const AuthGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Fungsi ini sekarang berada di dalam build agar bisa diakses oleh kedua form
    void showAuthSheet({required bool isLogin}) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor:
            Colors.transparent, // Form bisa ditutup saat klik di luar
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: isLogin ? 0.75 : 0.85, // Sesuaikan tinggi awal
            maxChildSize: isLogin ? 0.75 : 0.85, // Sesuaikan tinggi maksimal
            minChildSize: 0.5,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: isLogin
                    ? LoginForm(
                        scrollController: scrollController,
                        // Kirim fungsi untuk pindah ke register
                        onSwitchToRegister: () {
                          Navigator.pop(context); // Tutup login sheet
                          showAuthSheet(isLogin: false); // Buka register sheet
                        },
                      )
                    : RegisterForm(
                        scrollController: scrollController,
                        // Kirim fungsi untuk pindah ke login
                        onSwitchToLogin: () {
                          Navigator.pop(context); // Tutup register sheet
                          showAuthSheet(isLogin: true); // Buka login sheet
                        },
                      ),
              );
            },
          );
        },
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/images/auth_background.png'), // Sesuaikan path gambar Anda
                fit: BoxFit.cover, // Agar gambar memenuhi layar
              ),
            ),
          ),
// Tambahkan lapisan gradasi gelap agar teks lebih terbaca
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          // Lapisan gradasi gelap agar teks lebih terbaca
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Selamat Datang di Fleet Monitoring",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Solusi pemantauan armada CNG terintegrasi.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => showAuthSheet(isLogin: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Masuk", style: AppTextStyles.button),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => showAuthSheet(isLogin: false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.white),
                    ),
                    child: Text("Daftar",
                        style:
                            AppTextStyles.button.copyWith(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
