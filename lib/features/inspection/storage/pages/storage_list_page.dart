// lib/features/inspection/storage/pages/storage_list_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/inspection/providers/base_inspection_provider.dart';
import 'package:gasra_monitoring/features/inspection/providers/storage_inspection_provider.dart';
import 'package:gasra_monitoring/features/inspection/storage/pages/form_storage_page.dart';
import 'package:gasra_monitoring/features/report/pages/report_problem_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class StorageListPage extends StatefulWidget {
  final String storageType;
  final bool isForReport;

  const StorageListPage({
    super.key,
    required this.storageType,
    this.isForReport = false,
  });

  @override
  State<StorageListPage> createState() => _StorageListPageState();
}

class _StorageListPageState extends State<StorageListPage> {
  late Future<List<Map<String, dynamic>>> _storageFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _storageFuture = _fetchStoragesWithStatus(); // DIUBAH
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
  Future<List<Map<String, dynamic>>> _fetchStoragesWithStatus() async {
    final response =
        await SupabaseManager.client.rpc('get_storages_with_status');
    final allStorages = List<Map<String, dynamic>>.from(response);

    final feetValue = int.tryParse(widget.storageType.split(' ')[0]);
    if (feetValue == null) return [];

    final filteredStorages = allStorages.where((storage) {
      final int feet = storage['feet'] ?? 0;
      return feet == feetValue;
    }).toList();

    // [FIX] Logika pengurutan numerik ditambahkan di sini
    filteredStorages.sort((a, b) {
      final int numA = int.tryParse(a['storage_code'] ?? '99999') ?? 99999;
      final int numB = int.tryParse(b['storage_code'] ?? '99999') ?? 99999;
      return numA.compareTo(numB);
    });

    return filteredStorages;
  }

  // BARU
  void _handleStorageSelection(Map<String, dynamic> storage) async {
    final lastInspectionDateString = storage['last_inspection_date'];
    bool proceed = true;

    if (lastInspectionDateString != null) {
      final lastInspectionDate = DateTime.parse(lastInspectionDateString);
      final now = DateTime.now();
      final isSameDay = now.year == lastInspectionDate.year &&
          now.month == lastInspectionDate.month &&
          now.day == lastInspectionDate.day;

      if (isSameDay) {
        final inspectorName = storage['inspector_name'] ?? 'seseorang';
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
      _navigateToNextPage(storage);
    }
  }

  // BARU
  void _navigateToNextPage(Map<String, dynamic> storage) {
    final storageCode = storage['storage_code'] as String;
    final storageId = storage['id'].toString();

    if (widget.isForReport) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ReportProblemPage(
                    unitId: storageId,
                    unitCode: storageCode,
                    unitCategory: 'storages',
                    unitSubtype: widget.storageType,
                  )));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<BaseInspectionProvider>(
              create: (_) => StorageInspectionProvider(),
              child: FormStoragePage(
                storageCode: storageCode,
                storageId: storageId,
              ),
            ),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Storage (${widget.storageType})'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _storageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('Tidak ada data Storage untuk tipe ini.'));
          }

          final allStorages = snapshot.data!;
          final filteredStorages = allStorages.where((storage) {
            final storageCode = storage['storage_code'] as String;
            return storageCode
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
                    hintText: 'Cari kode storage...',
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
                child: filteredStorages.isEmpty
                    ? const Center(child: Text("Tidak ada hasil yang cocok."))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        itemCount: filteredStorages.length,
                        itemBuilder: (context, index) {
                          final storage = filteredStorages[index];
                          final storageCode = storage['storage_code'] as String;

                          // BARU: Logika status
                          final lastInspectionDate =
                              storage['last_inspection_date'];
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
                                  storage['inspector_name'] ?? 'N/A';
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
                                    storageCode,
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
                              onTap: () => _handleStorageSelection(storage),
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
