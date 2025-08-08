// lib/features/inspection/chassis/pages/chassis_list_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/inspection/chasis/pages/form_chassis_page.dart';
import 'package:gasra_monitoring/features/inspection/providers/base_inspection_provider.dart';
import 'package:gasra_monitoring/features/inspection/providers/chassis_inspection_provider.dart';
import 'package:gasra_monitoring/features/report/pages/report_problem_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ChassisListPage extends StatefulWidget {
  final String chassisSubtype;
  final bool isForReport;
  const ChassisListPage(
      {super.key, required this.chassisSubtype, this.isForReport = false});

  @override
  State<ChassisListPage> createState() => _ChassisListPageState();
}

class _ChassisListPageState extends State<ChassisListPage> {
  late Future<List<Map<String, dynamic>>> _chassisFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _chassisFuture = _fetchChassisWithStatus(); // DIUBAH
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

  // DIUBAH TOTAL
  Future<List<Map<String, dynamic>>> _fetchChassisWithStatus() async {
    final response =
        await SupabaseManager.client.rpc('get_chassis_with_status');
    final allChassis = List<Map<String, dynamic>>.from(response);

    final feetValue = int.tryParse(widget.chassisSubtype.split(' ')[0]);
    if (feetValue == null) return [];

    return allChassis.where((chassis) {
      final int feet = chassis['feet'] ?? 0;
      return feet == feetValue;
    }).toList();
  }

  // BARU
  void _handleChassisSelection(Map<String, dynamic> chassis) async {
    final lastInspectionDateString = chassis['last_inspection_date'];
    bool proceed = true;

    if (lastInspectionDateString != null) {
      final lastInspectionDate = DateTime.parse(lastInspectionDateString);
      final now = DateTime.now();
      final isSameDay = now.year == lastInspectionDate.year &&
          now.month == lastInspectionDate.month &&
          now.day == lastInspectionDate.day;

      if (isSameDay) {
        final inspectorName = chassis['inspector_name'] ?? 'seseorang';
        final bool? shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: Text(
                'Unit ini sudah diinspeksi hari ini oleh $inspectorName. Apakah Anda ingin melakukan inspeksi lagi?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Tidak')),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Ya, Lanjutkan')),
            ],
          ),
        );
        proceed = shouldProceed ?? false;
      }
    }

    if (proceed && mounted) {
      _navigateToNextPage(chassis);
    }
  }

  // BARU
  void _navigateToNextPage(Map<String, dynamic> chassis) {
    final chassisCode = chassis['chassis_code'] as String;
    final chassisId = chassis['id'].toString();

    if (widget.isForReport) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ReportProblemPage(
                    unitId: chassisId,
                    unitCode: chassisCode,
                    unitCategory: 'chassis',
                    unitSubtype: widget.chassisSubtype,
                  )));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<BaseInspectionProvider>(
              create: (_) => ChassisInspectionProvider(),
              child: FormChassisPage(
                chassisType: widget.chassisSubtype,
                chassisCode: chassisCode,
                chassisId: chassisId,
              ),
            ),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Chassis (${widget.chassisSubtype})'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _chassisFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('Tidak ada data Chassis untuk tipe ini.'));
          }

          final allChassis = snapshot.data!;
          final filteredChassis = allChassis.where((chassis) {
            final chassisCode = chassis['chassis_code'] as String;
            return chassisCode
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari kode chassis...',
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
                child: filteredChassis.isEmpty
                    ? const Center(child: Text("Tidak ada hasil yang cocok."))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        itemCount: filteredChassis.length,
                        itemBuilder: (context, index) {
                          final chassis = filteredChassis[index];
                          final chassisCode = chassis['chassis_code'] as String;

                          // BARU: Logika status
                          final lastInspectionDate =
                              chassis['last_inspection_date'];
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
                                  chassis['inspector_name'] ?? 'N/A';
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
                                    chassisCode,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  // [DIUBAH] Tambahkan pengecekan null
                                  if (statusWidget != null) ...[
                                    const SizedBox(height: 4),
                                    statusWidget, // Tampilkan status di sini
                                  ],
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.grey),
                              onTap: () => _handleChassisSelection(chassis),
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
