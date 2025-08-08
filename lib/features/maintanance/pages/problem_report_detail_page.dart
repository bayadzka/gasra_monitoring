// lib/features/maintenance/pages/problem_report_detail_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/maintanance/pages/repair_page.dart';

class ProblemReportDetailPage extends StatefulWidget {
  final String unitId;
  final String unitCode;
  final String unitCategory;

  const ProblemReportDetailPage({
    super.key,
    required this.unitId,
    required this.unitCode,
    required this.unitCategory,
  });

  @override
  State<ProblemReportDetailPage> createState() =>
      _ProblemReportDetailPageState();
}

class _ProblemReportDetailPageState extends State<ProblemReportDetailPage> {
  late Future<List<Map<String, dynamic>>> _problemsFuture;

  @override
  void initState() {
    super.initState();
    _problemsFuture = _fetchProblems();
  }

  Future<List<Map<String, dynamic>>> _fetchProblems() async {
    final unitIdColumn =
        '${widget.unitCategory.substring(0, widget.unitCategory.length - 1)}_id';

    // [FIX] Mengambil semua data dari VIEW untuk memastikan URL foto terbawa
    final response = await SupabaseManager.client
        .from('pending_repairs_view')
        .select('*')
        .eq(unitIdColumn, widget.unitId)
        .filter('inspection_id', 'is', null); // Filter hanya untuk laporan PTC

    return List<Map<String, dynamic>>.from(response);
  }

  void _navigateToRepairPage(Map<String, dynamic> item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RepairPage(item: item),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _problemsFuture = _fetchProblems();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detail Laporan ${widget.unitCode}"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _problemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Terjadi error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Semua masalah untuk unit ini sudah diperbaiki."),
            );
          }

          final items = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final itemName = item['item_name'] ?? 'Item tidak diketahui';
              final keterangan =
                  item['problem_notes'] ?? 'Tidak ada keterangan.';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(itemName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 4),
                      Text("Keterangan Masalah: $keterangan",
                          style: const TextStyle(color: Colors.black54)),
                      const Divider(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.build),
                          label: const Text("Catat Perbaikan"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            _navigateToRepairPage(item);
                          },
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
