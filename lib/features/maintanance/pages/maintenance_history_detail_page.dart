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
    final itemName =
        record['item_name'] ?? record['custom_title'] ?? 'Item tidak diketahui';
    final problemNotes =
        record['problem_notes'] ?? 'Tidak ada catatan masalah.';
    final repairNotes =
        record['repair_notes'] ?? 'Tidak ada catatan perbaikan.';
    final repairedBy = record['repaired_by'] ?? 'Tidak diketahui';
    final utcDate = DateTime.parse(record['repaired_at']);
    final localDate = utcDate.toLocal();
    final formattedDate = DateFormat('d MMMM yyyy, HH:mm').format(localDate);
    final problemPhotoUrl = record['problem_photo_url'];
    final repairPhotoUrl = record['repair_photo_url'];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title:
            Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeader("Detail Unit", "$unitCode ($unitType)"),
          const SizedBox(height: 24),
          _buildSectionTitle("Laporan Masalah"),
          _buildInfoCard("Item/Judul Masalah", itemName),
          _buildInfoCard("Keterangan Masalah", problemNotes),
          if (problemPhotoUrl != null)
            _buildPhotoCard(context, "Foto Masalah", problemPhotoUrl),
          const SizedBox(height: 24),
          _buildSectionTitle("Detail Perbaikan"),
          _buildInfoCard("Catatan Perbaikan", repairNotes),
          _buildInfoCard("Diperbaiki Oleh", repairedBy),
          _buildInfoCard("Tanggal Perbaikan", formattedDate,
              icon: Icons.calendar_today),
          if (repairPhotoUrl != null)
            _buildPhotoCard(context, "Foto Perbaikan", repairPhotoUrl),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.subtitle.copyWith(fontSize: 22)),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title,
          style: AppTextStyles.subtitle.copyWith(color: AppTheme.primary)),
    );
  }

  Widget _buildInfoCard(String title, String content, {IconData? icon}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading:
            icon != null ? Icon(icon, color: AppTheme.textSecondary) : null,
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textSecondary)),
        subtitle: Text(content,
            style: AppTextStyles.body
                .copyWith(color: AppTheme.textPrimary, fontSize: 16)),
      ),
    );
  }

  Widget _buildPhotoCard(BuildContext context, String title, String imageUrl) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(top: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showPhotoViewer(context, imageUrl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textSecondary)),
            ),
            Image.network(imageUrl,
                height: 200, width: double.infinity, fit: BoxFit.cover),
          ],
        ),
      ),
    );
  }
}
