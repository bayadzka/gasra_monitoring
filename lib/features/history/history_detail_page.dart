// lib/features/history/history_detail_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';

class HistoryDetailPage extends StatefulWidget {
  final String inspectionId;
  final String inspectionCode;
  final String inspectorName;

  const HistoryDetailPage({
    super.key,
    required this.inspectionId,
    required this.inspectionCode,
    required this.inspectorName,
  });

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  late Future<Map<String, List<Map<String, dynamic>>>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _fetchAndGroupInspectionDetails();
  }

  Future<Map<String, List<Map<String, dynamic>>>>
      _fetchAndGroupInspectionDetails() async {
    final response = await SupabaseManager.client
        .from('inspection_results')
        .select(
            'kondisi, keterangan, problem_photo_url, inspection_items(name, category)')
        .eq('inspection_id', widget.inspectionId);

    final List<Map<String, dynamic>> results =
        List<Map<String, dynamic>>.from(response);

    final Map<String, List<Map<String, dynamic>>> groupedResults = {};
    for (var result in results) {
      final category = result['inspection_items']['category'] ?? 'Lainnya';
      (groupedResults[category] ??= []).add(result);
    }
    return groupedResults;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Detail Inspeksi"),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text("Gagal memuat detail: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text("Tidak ada detail untuk inspeksi ini."));
          }

          final groupedData = snapshot.data!;
          final orderedCategories = [
            'Kondisi Ban',
            'Lampu',
            'Wiper',
            'Sistem Pengereman',
            'Per Head',
            'U Bolt+Tusukan Per',
            'Hubbolt Roda',
            'Engine',
            'Surat Kendaraan',
            'Tools & APAR',
            'Landingan',
            'Per Chasis',
            'Karet Chamber',
            'Baut Roda',
            'Mur Roda',
            'Dop Roda',
            'Per Luar Chamber',
            'Storage'
          ];
          final sortedKeys = groupedData.keys.toList()
            ..sort((a, b) => orderedCategories
                .indexOf(a)
                .compareTo(orderedCategories.indexOf(b)));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ringkasan Inspeksi",
                    style: AppTextStyles.title.copyWith(fontSize: 24)),
                const SizedBox(height: 8),
                Text("No. Unit: ${widget.inspectionCode}",
                    style: AppTextStyles.subtitle.copyWith(fontSize: 18)),
                const SizedBox(height: 4),
                Text(
                  "Diinspeksi oleh: ${widget.inspectorName}",
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                      fontSize: 15),
                ),
                const SizedBox(height: 24),
                ...sortedKeys.map((category) {
                  final items = groupedData[category]!;
                  return _buildSection(context, category, items);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Map<String, dynamic>> items) {
    return Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppTextStyles.subtitle.copyWith(fontSize: 18)),
              const Divider(),
              ...items.map((itemData) {
                final itemName = itemData['inspection_items']['name'];
                final kondisi = itemData['kondisi'];
                final keterangan = itemData['keterangan'] ?? '';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      kondisi == 'baik'
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.cancel, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(itemName,
                              style: const TextStyle(fontSize: 15))),
                      if (keterangan.isNotEmpty)
                        Expanded(
                            child: Text(keterangan,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey))),
                    ],
                  ),
                );
              }),
            ])));
  }
}
