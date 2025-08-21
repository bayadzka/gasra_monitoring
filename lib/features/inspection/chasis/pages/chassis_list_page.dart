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
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
    _chassisFuture = _fetchChassisWithStatus();
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

  Future<List<Map<String, dynamic>>> _fetchChassisWithStatus() async {
    final response =
        await SupabaseManager.client.rpc('get_chassis_with_status');
    final allChassis = List<Map<String, dynamic>>.from(response);

    final feetValue = int.tryParse(widget.chassisSubtype.split(' ')[0]);
    if (feetValue == null) return [];

    final filteredChassis = allChassis.where((chassis) {
      final int feet = chassis['feet'] ?? 0;
      return feet == feetValue;
    }).toList();

    filteredChassis.sort((a, b) {
      final int numA = int.tryParse(a['chassis_code'] ?? '99999') ?? 99999;
      final int numB = int.tryParse(b['chassis_code'] ?? '99999') ?? 99999;
      return numA.compareTo(numB);
    });

    return filteredChassis;
  }

  void _handleChassisSelection(Map<String, dynamic> chassis) async {
    final lastInspectionDateString = chassis['last_inspection_date'];
    bool proceed = true;

    // FIX: Tambahkan kondisi !widget.isForReport
    if (lastInspectionDateString != null && !widget.isForReport) {
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
                hintText: 'Cari kode chassis...',
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
              future: _chassisFuture,
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

                final allChassis = snapshot.data!;
                final filteredChassis = allChassis.where((chassis) {
                  final chassisCode = chassis['chassis_code'] as String;
                  return chassisCode
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredChassis.isEmpty) {
                  return const Center(
                      child: Text("Tidak ada hasil yang cocok."));
                }

                return AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredChassis.length,
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildUnitCard(filteredChassis[index]),
                          ),
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

  Widget _buildUnitCard(Map<String, dynamic> chassis) {
    final chassisCode = chassis['chassis_code'] as String;

    // Logika status hanya disiapkan jika BUKAN untuk lapor masalah
    Widget? statusSubtitle;
    Widget? statusIndicator;

    if (!widget.isForReport) {
      final lastInspectionDate = chassis['last_inspection_date'];
      bool hasBeenInspected = lastInspectionDate != null;
      Color statusColor = hasBeenInspected ? Colors.green : Colors.red;
      String statusText = 'Belum Diperiksa';
      if (hasBeenInspected) {
        statusText =
            'Terakhir diperiksa: ${DateFormat('d MMM yyyy').format(DateTime.parse(lastInspectionDate).toLocal())}';
      }
      statusSubtitle =
          Text(statusText, style: TextStyle(color: statusColor, fontSize: 12));
      statusIndicator = Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.circle, color: statusColor, size: 12),
      );
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () => _handleChassisSelection(chassis),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(chassisCode,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: statusSubtitle, // Tampilkan subtitle jika ada
        trailing: statusIndicator ??
            const Icon(Icons.arrow_forward_ios,
                size: 16), // Tampilkan indikator status atau panah
      ),
    );
  }
}
