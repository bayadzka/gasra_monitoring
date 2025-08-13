// lib/features/report/pages/report_type_selection_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/inspection/chasis/pages/chassis_type_selection_page.dart';
import 'package:gasra_monitoring/features/inspection/head/pages/head_type_selection_page.dart';
import 'package:gasra_monitoring/features/inspection/storage/pages/storage_type_selection.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ReportTypeSelectionPage extends StatelessWidget {
  const ReportTypeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Pilih Tipe Unit'),
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
              _buildTypeCard(
                context,
                icon: Icons.fire_truck_rounded,
                title: 'Head',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const HeadTypeSelectionPage(isForReport: true))),
              ),
              _buildTypeCard(
                context,
                icon: Icons.miscellaneous_services_rounded,
                title: 'Chassis',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const ChassisTypeSelectionPage(isForReport: true))),
              ),
              _buildTypeCard(
                context,
                icon: Icons.inventory_2_rounded,
                title: 'Storage',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const StorageTypeSelectionPage(isForReport: true))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        leading: Icon(icon, size: 32, color: AppTheme.primary),
        title: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        trailing:
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      ),
    );
  }
}
