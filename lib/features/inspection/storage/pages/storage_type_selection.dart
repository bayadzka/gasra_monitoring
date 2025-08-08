// lib/features/inspection/storage/pages/storage_type_selection_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/features/inspection/storage/pages/storage_list_page.dart';
import 'package:gasra_monitoring/core/theme.dart';

class StorageTypeSelectionPage extends StatelessWidget {
  final bool isForReport;
  const StorageTypeSelectionPage({super.key, this.isForReport = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Tipe Storage'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // [FIX] Tombol 10 Feet ditambahkan
            _buildTypeCard(
              context,
              icon: Icons.inventory_2_outlined,
              title: '10 Feet',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StorageListPage(
                          storageType: '10 Feet', isForReport: isForReport)),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildTypeCard(
              context,
              icon: Icons.inventory,
              title: '20 Feet',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StorageListPage(
                          storageType: '20 Feet', isForReport: isForReport)),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildTypeCard(
              context,
              icon: Icons.inventory_2,
              title: '40 Feet',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StorageListPage(
                          storageType: '40 Feet', isForReport: isForReport)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    // ... (Fungsi ini tidak berubah)
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
