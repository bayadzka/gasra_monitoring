// lib/features/report/pages/report_type_selection_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/inspection/chasis/pages/chassis_type_selection_page.dart';
import 'package:gasra_monitoring/features/inspection/head/pages/head_type_selection_page.dart';
import 'package:gasra_monitoring/features/inspection/storage/pages/storage_type_selection.dart';

class ReportTypeSelectionPage extends StatelessWidget {
  const ReportTypeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Tipe Unit'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildTypeCard(
            context,
            icon: Icons.fire_truck_outlined,
            title: 'Head',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // [PENTING] Kirim isForReport: true
                  builder: (context) =>
                      const HeadTypeSelectionPage(isForReport: true),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildTypeCard(
            context,
            icon: Icons.miscellaneous_services_outlined,
            title: 'Chassis',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // [PENTING] Kirim isForReport: true
                  builder: (context) =>
                      const ChassisTypeSelectionPage(isForReport: true),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildTypeCard(
            context,
            icon: Icons.inventory_2_outlined,
            title: 'Storage',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // [PENTING] Kirim isForReport: true
                  builder: (context) =>
                      const StorageTypeSelectionPage(isForReport: true),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    // ... (Fungsi ini sama seperti di halaman lain, tidak perlu diubah)
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Row(
            children: [
              Icon(icon, size: 32, color: AppTheme.primary),
              const SizedBox(width: 20),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
