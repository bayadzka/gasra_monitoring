// lib/features/auth/auth_gate_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/auth/login_page.dart';
import 'package:gasra_monitoring/features/auth/register_page.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AuthGatePage extends StatelessWidget {
  const AuthGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    void showAuthSheet({required bool isLogin}) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: isLogin ? 0.75 : 0.85,
            maxChildSize: isLogin ? 0.75 : 0.85,
            minChildSize: 0.5,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppTheme.background, // Warna latar disamakan
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: isLogin
                    ? LoginForm(
                        scrollController: scrollController,
                        onSwitchToRegister: () {
                          Navigator.pop(context);
                          showAuthSheet(isLogin: false);
                        },
                      )
                    : RegisterForm(
                        scrollController: scrollController,
                        onSwitchToLogin: () {
                          Navigator.pop(context);
                          showAuthSheet(isLogin: true);
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
                image: AssetImage('assets/images/auth_background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.8),
                  Colors.black.withOpacity(0.6)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: AnimationLimiter(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 500),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      const Text(
                        "Selamat Datang di Fleet Monitoring",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Solusi pemantauan armada CNG terintegrasi.",
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () => showAuthSheet(isLogin: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text("Masuk",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => showAuthSheet(isLogin: false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.white),
                        ),
                        child: const Text("Daftar",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
