// lib/features/maintenance/pages/maintenance_history_detail_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

class MaintenanceHistoryDetailPage extends StatelessWidget {
  final Map<String, dynamic> record;

  const MaintenanceHistoryDetailPage({super.key, required this.record});

  void _showPhotoViewer(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: NetworkImage(imageUrl),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained * 0.8,
              maxScale: PhotoViewComputedScale.covered * 2.0,
            ),
            Positioned(
              top: 16,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unitCode = record['unit_code'] ?? 'N/A';
    final unitType = record['unit_type'] ?? '';
    final itemName = record['item_name'] ?? 'Item tidak diketahui';
    final problemNotes = record['problem_notes'] ?? 'N/A';
    final repairNotes = record['repair_notes'] ?? 'Tidak ada catatan.';
    final repairedBy = record['repaired_by'] ?? 'Tidak diketahui';
    final utcDate = DateTime.parse(record['repaired_at']);
    final localDate = utcDate.toLocal(); // <-- Tambahkan baris ini
    final formattedDate =
        DateFormat('d MMMM yyyy, HH:mm').format(localDate); // Gunakan localDate
    final problemPhotoUrl = record['problem_photo_url'];
    final repairPhotoUrl = record['repair_photo_url'];

    return Scaffold(
      appBar: AppBar(
        title: Text(itemName),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeader("Detail Unit", "$unitCode ($unitType)"),
          const SizedBox(height: 16),
          _buildHeader("Detail Laporan Masalah", itemName),
          const Divider(),
          if (problemPhotoUrl != null)
            _buildPhotoCard(context, "Foto Masalah", problemPhotoUrl),
          _buildInfoCard("Keterangan Masalah", problemNotes),
          const SizedBox(height: 24),
          _buildHeader("Detail Perbaikan", "Dicatat oleh $repairedBy"),
          const Divider(),
          if (repairPhotoUrl != null)
            _buildPhotoCard(context, "Foto Perbaikan", repairPhotoUrl),
          _buildInfoCard("Catatan Perbaikan", repairNotes),
          _buildInfoCard("Tanggal Perbaikan", formattedDate,
              icon: Icons.calendar_today),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.subtitle),
        Text(subtitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoCard(String title, String content, {IconData? icon}) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: icon != null ? Icon(icon, color: AppTheme.primary) : null,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildPhotoCard(BuildContext context, String title, String imageUrl) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showPhotoViewer(context, imageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl,
                    height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
