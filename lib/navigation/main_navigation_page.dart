// lib/navigation/main_navigation_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
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
                          fontSize: 14, color: Colors.white.withOpacity(0.9))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    ),
  );
}

// 1. Halaman Hub untuk Menu "Inspeksi"
class InspectionHubPage extends StatelessWidget {
  const InspectionHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Mulai Inspeksi"),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: AnimationLimiter(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              _buildInspectionTypeCard(
                context,
                title: "Inspeksi Head",
                subtitle: "Pemeriksaan unit truk dan head",
                icon: Icons.fire_truck_rounded,
                color: AppTheme.logoRed,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const HeadTypeSelectionPage(isForReport: false))),
              ),
              _buildInspectionTypeCard(
                context,
                title: "Inspeksi Chassis",
                subtitle: "Pemeriksaan rangka dan roda",
                icon: Icons.miscellaneous_services_rounded,
                color: AppTheme.logoAbu,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ChassisTypeSelectionPage(
                            isForReport: false))),
              ),
              _buildInspectionTypeCard(
                context,
                title: "Inspeksi Storage",
                subtitle: "Pemeriksaan tabung dan katup",
                icon: Icons.inventory_2_rounded,
                color: AppTheme.logoBiru,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StorageTypeSelectionPage(
                            isForReport: false))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget baru untuk kartu tipe inspeksi
  Widget _buildInspectionTypeCard(BuildContext context,
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

// 2. Halaman Hub untuk Menu "Pencatatan"
class LoggingHubPage extends StatelessWidget {
  const LoggingHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Pencatatan"),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: AnimationLimiter(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              _buildMenuCard(
                context,
                title: "Lapor Masalah Cepat",
                subtitle: "Laporkan kerusakan unit di luar jadwal inspeksi",
                icon: Icons.warning_amber_rounded,
                color: Colors.red,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ReportTypeSelectionPage())),
              ),
              _buildMenuCard(
                context,
                title: "Catat Perbaikan",
                subtitle: "Input data perbaikan untuk unit yang bermasalah",
                icon: Icons.build_circle_rounded,
                color: Colors.orange,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MaintenanceListPage())),
              ),
              _buildMenuCard(
                context,
                title: "Catat Pencucian",
                subtitle: "Catat riwayat pencucian untuk unit storage",
                icon: Icons.wash_rounded,
                color: Colors.blue,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WashingLogPage())),
              ),
            ],
          ),
        ),
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Riwayat"),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: AnimationLimiter(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              _buildMenuCard(
                context,
                title: "Riwayat Inspeksi",
                subtitle: "Lihat semua hasil inspeksi yang telah selesai",
                icon: Icons.manage_search_rounded,
                color: Colors.teal,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HistoryPage())),
              ),
              _buildMenuCard(
                context,
                title: "Riwayat Pencucian",
                subtitle: "Lacak semua catatan pencucian unit storage",
                icon: Icons.water_drop_outlined,
                color: Colors.lightBlue,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WashingHistoryPage())),
              ),
              _buildMenuCard(
                context,
                title: "Riwayat Perbaikan",
                subtitle: "Lihat semua riwayat perbaikan yang telah dicatat",
                icon: Icons.history_edu_rounded,
                color: Colors.indigo,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MaintenanceHistoryPage())),
              ),
            ],
          ),
        ),
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
  int selectedIndex = 0;

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      HomePage(onNavigateToTab: onItemTapped), // <- Perubahan di sini
      const InspectionHubPage(),
      const LoggingHubPage(),
      const HistoryHubPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
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
            buildNavItem(Icons.dashboard_rounded, 'Beranda', 0),
            buildNavItem(Icons.fact_check_rounded, 'Inspeksi', 1),
            buildNavItem(Icons.edit_note_rounded, 'Pencatatan', 2),
            buildNavItem(Icons.history_rounded, 'Riwayat', 3),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk membuat setiap item navigasi dengan animasi
  Widget buildNavItem(IconData icon, String label, int index) {
    return InkWell(
      onTap: () => onItemTapped(index),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selectedIndex == index
              ? AppTheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selectedIndex == index
                    ? AppTheme.primary
                    : Colors.grey[600]),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: selectedIndex == index
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
