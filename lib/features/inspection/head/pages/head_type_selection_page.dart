// lib/features/inspection/head/pages/head_type_selection_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/features/inspection/head/pages/head_list_page.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class HeadTypeSelectionPage extends StatelessWidget {
  final bool isForReport;
  const HeadTypeSelectionPage({super.key, this.isForReport = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // [FIX] AppBar diubah agar sesuai tema baru
      appBar: AppBar(
        title: const Text('Pilih Tipe Head'),
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
                icon: Icons.local_shipping_outlined,
                title: 'Arm Roll 10 Feet',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => HeadListPage(
                            headSubtype: 'Arm Roll 10 Feet',
                            isForReport: isForReport))),
              ),
              _buildTypeCard(
                context,
                title: '20 Feet',
                icon: Icons.fire_truck_outlined,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => HeadListPage(
                            headSubtype: '20 Feet', isForReport: isForReport))),
              ),
              _buildTypeCard(
                context,
                title: '40 Feet',
                icon: Icons.fire_truck_rounded,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => HeadListPage(
                            headSubtype: '40 Feet', isForReport: isForReport))),
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
