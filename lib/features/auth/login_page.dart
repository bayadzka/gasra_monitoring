// lib/features/auth/widgets/login_form.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/auth/providers/auth_provider.dart';
import 'package:gasra_monitoring/features/dashboard/home_page.dart';
import 'package:provider/provider.dart';
import 'package:gasra_monitoring/core/services/notification_service.dart';

class LoginForm extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onSwitchToRegister;

  const LoginForm(
      {super.key,
      required this.scrollController,
      required this.onSwitchToRegister});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      final res = await SupabaseManager.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (mounted && res.user != null) {
        await context.read<AuthProvider>().loadUserProfile();
        await NotificationService().getTokenAndSave();

        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false);
      }
    } catch (e) {
      _showError("Login Gagal: Periksa kembali email dan password Anda.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.primary.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // [DIUBAH] Menggunakan SingleChildScrollView agar bisa di-scroll
    // dan Padding dinamis untuk mengatasi keyboard.
    return SingleChildScrollView(
      controller: widget.scrollController,
      // Padding ini akan secara otomatis mendorong konten ke atas saat keyboard muncul
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 5,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset('assets/images/logo.png', height: 70),
            const SizedBox(height: 16),
            const Text(
              "Selamat Datang Kembali",
              textAlign: TextAlign.center,
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 8),
            Text(
              "Masuk ke akun Anda",
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: emailController,
              decoration: _buildInputDecoration("Email", Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || !value.contains('@')) {
                  return 'Masukkan email yang valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: _obscureText,
              decoration: _buildInputDecoration("Password", Icons.lock_outline)
                  .copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : login,
              style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                  padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 16))),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text("Masuk"),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Belum punya akun?"),
                TextButton(
                  onPressed: widget.onSwitchToRegister,
                  child: const Text("Daftar di sini"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
