// lib/features/inspection/chassis/pages/chassis_type_selection_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/features/inspection/chasis/pages/chassis_list_page.dart';
import 'package:gasra_monitoring/core/theme.dart';

class ChassisTypeSelectionPage extends StatelessWidget {
  final bool isForReport;
  const ChassisTypeSelectionPage({super.key, this.isForReport = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Tipe Chassis'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            buildTypeCard(
              context,
              icon: Icons.fire_truck_outlined,
              title: '20 Feet',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      // [FIX] Pastikan nama parameter di sini adalah 'chassisSubtype'
                      builder: (context) => ChassisListPage(
                          chassisSubtype: '20 Feet', isForReport: isForReport)),
                );
              },
            ),
            const SizedBox(height: 16),
            buildTypeCard(
              context,
              title: '40 Feet',
              icon: Icons.fire_truck_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      // [FIX] Pastikan nama parameter di sini adalah 'chassisSubtype'
                      builder: (context) => ChassisListPage(
                          chassisSubtype: '40 Feet', isForReport: isForReport)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTypeCard(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
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
