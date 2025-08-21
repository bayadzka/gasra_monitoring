import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/auth/auth_gate_page.dart';
import 'package:gasra_monitoring/features/auth/providers/auth_provider.dart';
import 'package:gasra_monitoring/features/maintanance/pages/maintanance_history_page.dart';
import 'package:gasra_monitoring/features/report/pages/report_type_selection_page.dart';
import 'package:provider/provider.dart';

class PtcHomePage extends StatefulWidget {
  const PtcHomePage({super.key});

  @override
  State<PtcHomePage> createState() => _PtcHomePageState();
}

class _PtcHomePageState extends State<PtcHomePage> {
  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Ya, Keluar',
                  style: TextStyle(color: Colors.red.shade700))),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await SupabaseManager.client.auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGatePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Selamat Datang (PTC),",
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            Text(authProvider.userName ?? 'Pengguna',
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
            onPressed: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMenuCard(
            context,
            title: "Lapor Masalah Cepat",
            subtitle: "Laporkan kerusakan unit di luar jadwal",
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ReportTypeSelectionPage()),
            ),
          ),
          _buildMenuCard(
            context,
            title: "Riwayat Perbaikan",
            subtitle: "Lihat semua riwayat perbaikan yang telah dicatat",
            icon: Icons.history_edu_rounded,
            color: Colors.indigo,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MaintenanceHistoryPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      elevation: 5,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withOpacity(0.9),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9))),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
