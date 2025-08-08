// lib/features/maintenance/pages/maintenance_history_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/maintanance/pages/maintenance_history_detail_page.dart';
import 'package:intl/intl.dart';

class MaintenanceHistoryPage extends StatefulWidget {
  const MaintenanceHistoryPage({super.key});

  @override
  State<MaintenanceHistoryPage> createState() => _MaintenanceHistoryPageState();
}

class _MaintenanceHistoryPageState extends State<MaintenanceHistoryPage> {
  late Future<List<Map<String, dynamic>>> _historyFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchMaintenanceHistory();
    _searchController.addListener(() {
      if (mounted) setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchMaintenanceHistory() async {
    final response =
        await SupabaseManager.client.rpc('get_maintenance_history');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Widget _buildChip(String label, int count, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedFilter = label;
            });
          }
        },
        selectedColor: AppTheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.grey[200],
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: isSelected ? AppTheme.primary : Colors.grey.shade300)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Perbaikan"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Terjadi error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada riwayat perbaikan."));
          }

          final allRecords = snapshot.data!;
          final categoryFiltered = allRecords.where((record) {
            final type = record['unit_type'] as String? ?? '';
            if (_selectedFilter == 'Semua') return true;
            return type == _selectedFilter;
          }).toList();
          final filteredRecords = categoryFiltered.where((record) {
            final unitCode = record['unit_code'] as String? ?? '';
            return unitCode.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
          final counts = {
            'Head': allRecords
                .where((r) => (r['unit_type'] as String? ?? '') == 'Head')
                .length,
            'Chassis': allRecords
                .where((r) => (r['unit_type'] as String? ?? '') == 'Chassis')
                .length,
            'Storage': allRecords
                .where((r) => (r['unit_type'] as String? ?? '') == 'Storage')
                .length,
          };

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari berdasarkan kode unit...',
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
              Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      _buildChip('Semua', allRecords.length,
                          _selectedFilter == 'Semua'),
                      _buildChip(
                          'Head', counts['Head']!, _selectedFilter == 'Head'),
                      _buildChip('Chassis', counts['Chassis']!,
                          _selectedFilter == 'Chassis'),
                      _buildChip('Storage', counts['Storage']!,
                          _selectedFilter == 'Storage'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => setState(
                      () => _historyFuture = _fetchMaintenanceHistory()),
                  child: filteredRecords.isEmpty
                      ? const Center(child: Text("Tidak ada hasil yang cocok."))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          itemCount: filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = filteredRecords[index];
                            final unitCode = record['unit_code'] ?? 'N/A';
                            final unitType = record['unit_type'] ?? '';
                            final itemName =
                                record['item_name'] ?? 'Item tidak diketahui';
                            final problemNotes =
                                record['problem_notes'] ?? 'N/A';
                            final repairNotes =
                                record['repair_notes'] ?? 'Tidak ada catatan.';
                            final repairedBy =
                                record['repaired_by'] ?? 'Tidak diketahui';
                            final date = DateTime.parse(record['repaired_at']);
                            final formattedDate =
                                DateFormat('d MMMM yyyy, HH:mm').format(date);
                            IconData unitIcon = Icons.article;
                            if (unitType == 'Head')
                              unitIcon = Icons.fire_truck_outlined;
                            else if (unitType == 'Chassis')
                              unitIcon = Icons.miscellaneous_services_outlined;
                            else if (unitType == 'Storage')
                              unitIcon = Icons.inventory_2_outlined;

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              child: ListTile(
                                // [DIUBAH] Menggunakan ListTile agar bisa onTap
                                contentPadding: const EdgeInsets.all(16),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              MaintenanceHistoryDetailPage(
                                                  record: record as Map<String,
                                                      dynamic>)));
                                },
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color:
                                            AppTheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(unitIcon,
                                              color: AppTheme.primary,
                                              size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "$unitCode ($unitType)",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: AppTheme.primary),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 24),
                                    Text(itemName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                            color: Colors.black87)),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                        Icons.report_problem_outlined,
                                        "Masalah:",
                                        problemNotes,
                                        Colors.red[700]),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                        Icons.build_circle_outlined,
                                        "Perbaikan:",
                                        repairNotes,
                                        Colors.green[800]),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                        Icons.person_outline,
                                        "Diperbaiki Oleh:",
                                        repairedBy,
                                        Colors.grey[700]),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                        Icons.calendar_today_outlined,
                                        "Tanggal:",
                                        formattedDate,
                                        Colors.grey[700]),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      [Color? iconColor]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Text("$label ", style: TextStyle(color: Colors.grey[700])),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }
}
