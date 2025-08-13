// lib/features/inspection/head/pages/head_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
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
    _headsFuture = _fetchHeadsWithStatus();
    _searchController.addListener(() {
      if (mounted) setState(() => _searchQuery = _searchController.text);
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
      // [FIX] AppBar diubah agar sesuai tema baru
      appBar: AppBar(
        title: Text('Pilih Head (${widget.headSubtype})'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nomor polisi...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _headsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Terjadi error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("Tidak ada data unit untuk tipe ini."));
                }

                final allHeads = snapshot.data!;
                final filteredHeads = allHeads.where((head) {
                  final headCode = head['head_code'] as String;
                  return headCode
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredHeads.isEmpty) {
                  return const Center(
                      child: Text("Tidak ada hasil yang cocok."));
                }

                return AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredHeads.length,
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                              child: _buildUnitCard(filteredHeads[index])),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(Map<String, dynamic> head) {
    final headCode = head['head_code'] as String;
    final lastInspectionDate = head['last_inspection_date'];

    bool hasBeenInspected = lastInspectionDate != null;
    Color statusColor = hasBeenInspected ? Colors.green : Colors.red;
    String statusText = 'Belum Diperiksa';
    if (hasBeenInspected) {
      statusText =
          'Terakhir diperiksa: ${DateFormat('d MMM yyyy').format(DateTime.parse(lastInspectionDate).toLocal())}';
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () => _handleHeadSelection(head),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(headCode,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: widget.isForReport
            ? null
            : Text(statusText,
                style: TextStyle(color: statusColor, fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.circle, color: statusColor, size: 12),
        ),
      ),
    );
  }
}
