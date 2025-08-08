// lib/features/dashboard/home_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/auth/auth_gate_page.dart';
import 'package:gasra_monitoring/features/auth/providers/auth_provider.dart';
import 'package:gasra_monitoring/features/history/history_page.dart';
import 'package:gasra_monitoring/features/inspection/chasis/pages/chassis_type_selection_page.dart';
import 'package:gasra_monitoring/features/inspection/head/pages/head_type_selection_page.dart';
import 'package:gasra_monitoring/features/inspection/storage/pages/storage_type_selection.dart';
import 'package:gasra_monitoring/features/maintanance/pages/maintanance_history_page.dart';
import 'package:gasra_monitoring/features/maintanance/pages/maintenance_list_page.dart';
import 'package:gasra_monitoring/features/report/pages/report_type_selection_page.dart';
import 'package:gasra_monitoring/features/washing/pages/washing_history_page.dart';
import 'package:gasra_monitoring/features/washing/pages/washing_log_page.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userRole = authProvider.userRole;

    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // [DIUBAH] Logika pembangunan menu diatur ulang di sini
    List<Widget> menuInspeksi = [];
    List<Widget> menuLainnya = [];

    // Tombol ini sekarang dibutuhkan oleh kedua role
    final laporMasalahButton = _buildMenuButton(
        icon: Icons.report_problem_outlined,
        label: "Lapor Masalah Cepat",
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ReportTypeSelectionPage())));

    if (userRole == 'ptc') {
      menuLainnya = [
        laporMasalahButton, // Tambahkan tombol di sini
        _buildMenuButton(
            icon: Icons.history_edu_outlined,
            label: "Riwayat Perbaikan",
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MaintenanceHistoryPage()))),
      ];
    } else {
      // Role selain 'ptc' (misal: 'web_mobile')
      menuInspeksi = [
        _buildMenuButton(
            icon: Icons.fire_truck_outlined,
            label: "Form Head",
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const HeadTypeSelectionPage(isForReport: false)))),
        _buildMenuButton(
            icon: Icons.miscellaneous_services_outlined,
            label: "Form Chasis",
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const ChassisTypeSelectionPage(isForReport: false)))),
        _buildMenuButton(
            icon: Icons.inventory_2_outlined,
            label: "Form Storage",
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const StorageTypeSelectionPage(isForReport: false)))),
      ];

      menuLainnya = [
        laporMasalahButton, // [BARU] Tambahkan tombol di sini juga
        _buildMenuButton(
            icon: Icons.history_outlined,
            label: "Riwayat Inspeksi",
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryPage()))),
        _buildMenuButton(
            icon: Icons.build_circle_outlined,
            label: "Perlu Perbaikan",
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MaintenanceListPage()))),
        _buildMenuButton(
            icon: Icons.plumbing_outlined,
            label: "Record Maintenance",
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MaintenanceHistoryPage()))),
        _buildMenuButton(
            icon: Icons.wash_outlined,
            label: "Catat Pencucian",
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WashingLogPage()))),
        _buildMenuButton(
            icon: Icons.history_edu_outlined,
            label: "Riwayat Pencucian",
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WashingHistoryPage()))),
      ];
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
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
              if (shouldLogout == true) {
                await SupabaseManager.client.auth.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthGatePage()),
                      (route) => false);
                }
              }
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AuthProvider>().loadUserProfile(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text("Selamat Datang,",
                style: TextStyle(fontSize: 20, color: Colors.grey[700])),
            Text(authProvider.userName ?? 'Pengguna',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary)),
            const SizedBox(height: 24),
            if (userRole != 'ptc')
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HistoryPage()));
                      },
                      child: _buildMetricCard(
                        icon: Icons.calendar_today,
                        label: "Inspeksi Bulan Ini",
                        value: authProvider.isStatsLoading
                            ? '...'
                            : authProvider.inspeksiBulanIni.toString(),
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MaintenanceListPage()));
                      },
                      child: _buildMetricCard(
                        icon: Icons.warning_amber_rounded,
                        label: "Perlu Perbaikan",
                        value: authProvider.isStatsLoading
                            ? '...'
                            : authProvider.perluPerbaikan.toString(),
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            if (userRole != 'ptc') const SizedBox(height: 24),
            if (menuInspeksi.isNotEmpty) ...[
              const Text("Menu Inspeksi", style: AppTextStyles.subtitle),
              const Divider(height: 16),
              ...menuInspeksi,
              const SizedBox(height: 24),
            ],
            const Text("Menu Lainnya", style: AppTextStyles.subtitle),
            const Divider(height: 16),
            ...menuLainnya,
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[200]!)),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color, size: 22)),
              const SizedBox(height: 12),
              Text(value,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ])));
  }

  Widget _buildMenuButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!)),
        child: ListTile(
            onTap: onTap,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Icon(icon, size: 28, color: AppTheme.primary),
            title: Text(label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16)));
  }
}
