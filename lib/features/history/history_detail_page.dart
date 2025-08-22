// lib/features/history/history_detail_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:photo_view/photo_view.dart';

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

    // [FIX] Mengurutkan item di dalam setiap kategori dengan logika baru
    groupedResults.forEach((category, items) {
      items.sort((a, b) {
        final itemA = a['inspection_items']?['name'] ?? '';
        final itemB = b['inspection_items']?['name'] ?? '';

        // Ekstrak bagian nama (tanpa angka dan L/R)
        final namePartA = itemA.replaceAll(RegExp(r'\s?[LR]?\d+.*'), '');
        final namePartB = itemB.replaceAll(RegExp(r'\s?[LR]?\d+.*'), '');

        // Urutkan berdasarkan nama dulu
        final nameCompare = namePartA.compareTo(namePartB);
        if (nameCompare != 0) {
          return nameCompare;
        }

        // Jika nama sama, urutkan berdasarkan angka
        final numA = int.tryParse(itemA.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final numB = int.tryParse(itemB.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final numCompare = numA.compareTo(numB);
        if (numCompare != 0) {
          return numCompare;
        }

        // Jika angka sama, urutkan berdasarkan L/R (L dulu baru R)
        final sideA = itemA.contains('L') ? 0 : (itemA.contains('R') ? 1 : 2);
        final sideB = itemB.contains('L') ? 0 : (itemB.contains('R') ? 1 : 2);
        return sideA.compareTo(sideB);
      });
    });

    return groupedResults;
  }

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
            ),
            Positioned(
              top: 40,
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
            'Ban dan Roda',
            'Kondisi Ban',
            'Lampu',
            'Wiper',
            'Sistem Pengereman',
            'Per Head',
            'Per Chasis',
            'U Bolt+Tusukan Per',
            'Hubbolt Roda',
            'Engine',
            'Surat Kendaraan',
            'Tools & Apar',
            'Tools & Safety',
            'Landingan',
            'Karet Chamber',
            'Baut Roda',
            'Mur Roda',
            'Dop Roda',
            'Per Luar Chamber',
            'Pendukung Utama',
            'Tanki',
            'Hydrolik',
            'PTO',
            'Kaki-kaki',
            'Storage'
          ];
          final sortedKeys = groupedData.keys.toList()
            ..sort((a, b) {
              int indexA = orderedCategories.indexOf(a);
              int indexB = orderedCategories.indexOf(b);
              if (indexA == -1) indexA = orderedCategories.length;
              if (indexB == -1) indexB = orderedCategories.length;
              return indexA.compareTo(indexB);
            });

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.subtitle.copyWith(fontSize: 18)),
            const Divider(),
            Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FlexColumnWidth(),
                2: IntrinsicColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: items.map((itemData) {
                final itemName = itemData['inspection_items']?['name'] ?? 'N/A';
                final kondisi = itemData['kondisi'];
                final keterangan = itemData['keterangan'] ?? '';
                final photoUrl = itemData['problem_photo_url'];

                return TableRow(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 12.0, top: 8, bottom: 8),
                      child: kondisi == 'baik'
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.cancel, color: Colors.red),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child:
                          Text(itemName, style: const TextStyle(fontSize: 15)),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 12.0, top: 8, bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (keterangan.isNotEmpty)
                            Flexible(
                              child: Text(
                                keterangan,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (photoUrl != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.photo_camera,
                                  color: AppTheme.primary, size: 20),
                              onPressed: () =>
                                  _showPhotoViewer(context, photoUrl),
                            )
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
