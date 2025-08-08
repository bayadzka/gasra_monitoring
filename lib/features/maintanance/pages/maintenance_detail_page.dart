// lib/features/maintenance/pages/maintenance_detail_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/maintanance/pages/repair_page.dart'; // [FIX] Import halaman repair_page.dart
import 'package:intl/intl.dart';

class MaintenanceDetailPage extends StatefulWidget {
  // [DIUBAH] Menjadi StatefulWidget
  final String unitCode;
  final List<Map<String, dynamic>> items;

  const MaintenanceDetailPage({
    super.key,
    required this.unitCode,
    required this.items,
  });

  @override
  State<MaintenanceDetailPage> createState() => _MaintenanceDetailPageState();
}

class _MaintenanceDetailPageState extends State<MaintenanceDetailPage> {
  // [BARU] Kelola daftar item di dalam state agar bisa di-refresh
  late List<Map<String, dynamic>> _currentItems;

  @override
  void initState() {
    super.initState();
    _currentItems = widget.items;
  }

  @override
  Widget build(BuildContext context) {
    // Mengurutkan item berdasarkan tanggal laporan terbaru
    _currentItems.sort((a, b) => DateTime.parse(b['reported_at'])
        .compareTo(DateTime.parse(a['reported_at'])));

    return Scaffold(
      appBar: AppBar(
        title: Text("Detail Masalah: ${widget.unitCode}"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _currentItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text("Semua masalah pada unit ini sudah diperbaiki!",
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _currentItems.length,
              itemBuilder: (context, index) {
                final item = _currentItems[index];
                final reportType = item['report_type'];

                final title = item['custom_title'] ??
                    item['item_name'] ??
                    'Masalah Tidak Dikenal';
                final notes = item['problem_notes'] ?? 'Tidak ada keterangan.';
                final reportedBy = item['reported_by'] ?? 'N/A';
                final date = DateTime.parse(item['reported_at']);
                final formattedDate =
                    DateFormat('d MMMM yyyy, HH:mm').format(date);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.subtitle.copyWith(fontSize: 18),
                        ),
                        const Divider(),
                        _buildDetailRow(Icons.person_outline, "Dilaporkan oleh",
                            reportedBy),
                        _buildDetailRow(Icons.calendar_today_outlined,
                            "Tanggal Laporan", formattedDate),
                        _buildDetailRow(
                            Icons.flag_outlined,
                            "Sumber Laporan",
                            reportType == 'inspection'
                                ? 'Inspeksi Reguler'
                                : 'Laporan Cepat'),
                        const SizedBox(height: 8),
                        Text("Keterangan:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700])),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              Text(notes, style: const TextStyle(fontSize: 15)),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.build_outlined, size: 18),
                            label: const Text("Catat Perbaikan"),
                            onPressed: () async {
                              // [FIX] Navigasi ke RepairPage dan mengirim 'item' yang benar
                              final bool? result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RepairPage(
                                    item:
                                        item, // Mengirim seluruh data map 'item'
                                  ),
                                ),
                              );
                              // [BARU] Jika perbaikan berhasil, hapus item dari daftar
                              if (result == true) {
                                setState(() {
                                  _currentItems.removeAt(index);
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text("$label:",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
