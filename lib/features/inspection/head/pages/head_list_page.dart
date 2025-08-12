// lib/features/inspection/head/pages/head_list_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/inspection/providers/base_inspection_provider.dart';
import 'package:gasra_monitoring/features/inspection/providers/head_inspection_provider.dart';
import 'package:gasra_monitoring/features/inspection/head/pages/form_head_page.dart';
import 'package:gasra_monitoring/features/report/pages/report_problem_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HeadListPage extends StatefulWidget {
  final String headSubtype;
  final bool isForReport;
  const HeadListPage(
      {super.key, required this.headSubtype, this.isForReport = false});

  @override
  State<HeadListPage> createState() => _HeadListPageState();
}

class _HeadListPageState extends State<HeadListPage> {
  late Future<List<Map<String, dynamic>>> _headsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _headsFuture = _fetchHeadsWithStatus(); // DIUBAH: Panggil fungsi baru
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // DIUBAH TOTAL: Fungsi ini sekarang memanggil RPC dan melakukan filter di sisi klien
  Future<List<Map<String, dynamic>>> _fetchHeadsWithStatus() async {
    final response = await SupabaseManager.client.rpc('get_heads_with_status');
    final allHeads = List<Map<String, dynamic>>.from(response);
    final subtype = widget.headSubtype;

    final filteredHeads = allHeads.where((head) {
      final String type = head['type'] ?? '';
      final int feet = head['feet'] ?? 0;

      if (subtype == 'Arm Roll 10 Feet') {
        return type == 'Arm Roll' && feet == 10;
      } else if (subtype == '20 Feet') {
        return type != 'Arm Roll' && feet == 20;
      } else if (subtype == '40 Feet') {
        return type != 'Arm Roll' && feet == 40;
      }
      return false;
    }).toList();

    // [FIX] Logika pengurutan numerik ditambahkan di sini
    filteredHeads.sort((a, b) {
      final String codeA =
          a['head_code']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '99999';
      final String codeB =
          b['head_code']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '99999';
      final int numA = int.tryParse(codeA) ?? 99999;
      final int numB = int.tryParse(codeB) ?? 99999;
      return numA.compareTo(numB);
    });

    return filteredHeads;
  }

  // BARU: Fungsi untuk menangani logika saat item dipilih
  void _handleHeadSelection(Map<String, dynamic> head) async {
    final lastInspectionDateString = head['last_inspection_date'];
    bool proceed = true; // Defaultnya, kita lanjutkan navigasi

    if (lastInspectionDateString != null && !widget.isForReport) {
      final lastInspectionDate = DateTime.parse(lastInspectionDateString);
      final now = DateTime.now();

      // Cek apakah inspeksi terakhir dilakukan pada hari yang sama
      final isSameDay = now.year == lastInspectionDate.year &&
          now.month == lastInspectionDate.month &&
          now.day == lastInspectionDate.day;

      if (isSameDay) {
        // Jika ya, tampilkan dialog konfirmasi
        final inspectorName = head['inspector_name'] ?? 'seseorang';
        final bool? shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: Text(
                'Unit ini sudah diinspeksi hari ini oleh $inspectorName. Apakah Anda ingin melakukan inspeksi lagi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Tidak'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Ya, Lanjutkan'),
              ),
            ],
          ),
        );
        proceed = shouldProceed ?? false;
      }
    }

    // Jika user memilih untuk melanjutkan (atau jika tidak ada inspeksi hari ini),
    // lakukan navigasi.
    if (proceed && mounted) {
      _navigateToNextPage(head);
    }
  }

  // BARU: Fungsi untuk navigasi (agar tidak duplikat kode)
  void _navigateToNextPage(Map<String, dynamic> head) {
    final headCode = head['head_code'] as String;
    final headId = head['id'].toString();

    if (widget.isForReport) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ReportProblemPage(
                    unitId: headId,
                    unitCode: headCode,
                    unitCategory: 'heads',
                    unitSubtype: widget.headSubtype,
                  )));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<BaseInspectionProvider>(
              create: (_) => HeadInspectionProvider(),
              child: FormHeadPage(
                headType: widget.headSubtype,
                headCode: headCode,
                headId: headId,
              ),
            ),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Head (${widget.headSubtype})'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _headsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Tampilkan pesan error yang lebih informatif
            return Center(child: Text('Terjadi error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text("Tidak ada data unit untuk tipe ini."));
          }

          final allHeads = snapshot.data!;
          final filteredHeads = allHeads.where((head) {
            final headCode = head['head_code'] as String;
            return headCode.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nomor polisi...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              Expanded(
                child: filteredHeads.isEmpty
                    ? const Center(child: Text("Tidak ada hasil yang cocok."))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        itemCount: filteredHeads.length,
                        itemBuilder: (context, index) {
                          final head = filteredHeads[index];
                          final headCode = head['head_code'] as String;

                          // BARU: Logika untuk menampilkan status inspeksi
                          final lastInspectionDate =
                              head['last_inspection_date'];
                          Widget? statusWidget; // Jadikan nullable

// HANYA TAMPILKAN STATUS JIKA BUKAN UNTUK REPORT
                          if (!widget.isForReport) {
                            if (lastInspectionDate == null) {
                              statusWidget = const Text(
                                'Belum pernah diinspeksi',
                                style:
                                    TextStyle(fontSize: 13, color: Colors.red),
                              );
                            } else {
                              final date = DateTime.parse(lastInspectionDate);
                              final formattedDate =
                                  DateFormat('d MMM yyyy').format(date);
                              final inspectorName =
                                  head['inspector_name'] ?? 'N/A';
                              statusWidget = Text(
                                'Terakhir inspeksi: $formattedDate oleh $inspectorName',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.green),
                              );
                            }
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: ListTile(
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    headCode,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (statusWidget != null) ...[
                                    const SizedBox(height: 4),
                                    statusWidget, // Tampilkan status di sini
                                  ], // Tampilkan status di sini
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.grey),
                              onTap: () {
                                // Panggil fungsi handler yang baru
                                _handleHeadSelection(head);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
