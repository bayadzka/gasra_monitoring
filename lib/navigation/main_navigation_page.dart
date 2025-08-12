// lib/navigation/main_navigation_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/theme.dart';

// Halaman-halaman utama kita
import 'package:gasra_monitoring/features/dashboard/home_page.dart'; // Halaman Beranda
import 'package:gasra_monitoring/features/inspection/head/pages/head_type_selection_page.dart';
import 'package:gasra_monitoring/features/inspection/chasis/pages/chassis_type_selection_page.dart';
import 'package:gasra_monitoring/features/inspection/storage/pages/storage_type_selection.dart';
import 'package:gasra_monitoring/features/maintanance/pages/maintanance_history_page.dart';
import 'package:gasra_monitoring/features/report/pages/report_type_selection_page.dart';
import 'package:gasra_monitoring/features/maintanance/pages/maintenance_list_page.dart';
import 'package:gasra_monitoring/features/washing/pages/washing_log_page.dart';
import 'package:gasra_monitoring/features/history/history_page.dart';
import 'package:gasra_monitoring/features/washing/pages/washing_history_page.dart';

// 1. Halaman Hub untuk Menu "Inspeksi"
class InspectionHubPage extends StatelessWidget {
  const InspectionHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inspeksi")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMenuButton(
            context,
            icon: Icons.fire_truck_outlined,
            label: "Form Head",
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const HeadTypeSelectionPage(isForReport: false))),
          ),
          _buildMenuButton(
            context,
            icon: Icons.miscellaneous_services_outlined,
            label: "Form Chasis",
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const ChassisTypeSelectionPage(isForReport: false))),
          ),
          _buildMenuButton(
            context,
            icon: Icons.inventory_2_outlined,
            label: "Form Storage",
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const StorageTypeSelectionPage(isForReport: false))),
          ),
        ],
      ),
    );
  }
}

// 2. Halaman Hub untuk Menu "Pencatatan"
class LoggingHubPage extends StatelessWidget {
  const LoggingHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pencatatan")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMenuButton(
            context,
            icon: Icons.warning_amber_rounded,
            label: "Lapor Masalah Cepat",
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ReportTypeSelectionPage())),
          ),
          _buildMenuButton(
            context,
            icon: Icons.build_circle_outlined,
            label: "Catat Perbaikan",
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MaintenanceListPage())),
          ),
          _buildMenuButton(
            context,
            icon: Icons.wash_outlined,
            label: "Catat Pencucian",
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WashingLogPage())),
          ),
        ],
      ),
    );
  }
}

// 3. Halaman Hub untuk Menu "Riwayat"
class HistoryHubPage extends StatelessWidget {
  const HistoryHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMenuButton(
            context,
            icon: Icons.history_outlined,
            label: "Riwayat Inspeksi",
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryPage())),
          ),
          _buildMenuButton(
            context,
            icon: Icons.history_edu_outlined,
            label: "Riwayat Pencucian",
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WashingHistoryPage())),
          ),
          _buildMenuButton(
            context,
            icon: Icons.plumbing_outlined,
            label: "Record Maintenance",
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MaintenanceHistoryPage())),
          ),
        ],
      ),
    );
  }
}

// Kerangka Utama Aplikasi dengan Navigasi Bawah
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      HomePage(onNavigateToTab: _onItemTapped), // <- Perubahan di sini
      const InspectionHubPage(),
      const LoggingHubPage(),
      const HistoryHubPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.dashboard_rounded, 'Beranda', 0),
            _buildNavItem(Icons.fact_check_rounded, 'Inspeksi', 1),
            _buildNavItem(Icons.edit_note_rounded, 'Pencatatan', 2),
            _buildNavItem(Icons.history_rounded, 'Riwayat', 3),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk membuat setiap item navigasi dengan animasi
  Widget _buildNavItem(IconData icon, String label, int index) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedIndex == index
              ? AppTheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: _selectedIndex == index
                    ? AppTheme.primary
                    : Colors.grey[600]),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: _selectedIndex == index
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget untuk tombol menu di halaman Hub
Widget _buildMenuButton(BuildContext context,
    {required IconData icon,
    required String label,
    required VoidCallback onTap}) {
  return Card(
    elevation: 2,
    margin: const EdgeInsets.only(bottom: 12),
    shadowColor: AppTheme.primary.withOpacity(0.1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(icon, size: 28, color: AppTheme.primary),
      title: Text(label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    ),
  );
}
