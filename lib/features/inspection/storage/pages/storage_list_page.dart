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
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
    _storageFuture = _fetchStoragesWithStatus();
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

    filteredStorages.sort((a, b) {
      final int numA = int.tryParse(a['storage_code'] ?? '99999') ?? 99999;
      final int numB = int.tryParse(b['storage_code'] ?? '99999') ?? 99999;
      return numA.compareTo(numB);
    });

    return filteredStorages;
  }

  void _handleStorageSelection(Map<String, dynamic> storage) async {
    final lastInspectionDateString = storage['last_inspection_date'];
    bool proceed = true;

    if (lastInspectionDateString != null && !widget.isForReport) {
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
                hintText: 'Cari kode storage...',
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
              future: _storageFuture,
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
                      child: Text('Tidak ada data Storage untuk tipe ini.'));
                }

                final allStorages = snapshot.data!;
                final filteredStorages = allStorages.where((storage) {
                  final storageCode = storage['storage_code'] as String;
                  return storageCode
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredStorages.isEmpty) {
                  return const Center(
                      child: Text("Tidak ada hasil yang cocok."));
                }

                return AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredStorages.length,
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildUnitCard(filteredStorages[index]),
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

  Widget _buildUnitCard(Map<String, dynamic> storage) {
    final storageCode = storage['storage_code'] as String;
    final lastInspectionDate = storage['last_inspection_date'];

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
        onTap: () => _handleStorageSelection(storage),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(storageCode,
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
