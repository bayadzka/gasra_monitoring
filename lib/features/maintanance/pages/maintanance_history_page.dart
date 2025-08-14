// lib/features/maintenance/pages/maintenance_history_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
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

  Color _getColorForUnitType(String type) {
    switch (type) {
      case 'Head':
        return AppTheme.logoRed;
      case 'Chassis':
        return AppTheme.logoAbu;
      case 'Storage':
        return AppTheme.logoBiru;
      default:
        return Colors.grey;
    }
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Riwayat Perbaikan"),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan kode unit...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Terjadi error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("Belum ada riwayat perbaikan."));
                }

                final allRecords = snapshot.data!;
                final categoryFiltered = allRecords.where((record) {
                  final type = record['unit_type'] as String? ?? '';
                  if (_selectedFilter == 'Semua') return true;
                  return type == _selectedFilter;
                }).toList();
                final filteredRecords = categoryFiltered.where((record) {
                  final unitCode = record['unit_code'] as String? ?? '';
                  return unitCode
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                }).toList();
                final counts = {
                  'Head': allRecords
                      .where((r) => (r['unit_type'] as String? ?? '') == 'Head')
                      .length,
                  'Chassis': allRecords
                      .where(
                          (r) => (r['unit_type'] as String? ?? '') == 'Chassis')
                      .length,
                  'Storage': allRecords
                      .where(
                          (r) => (r['unit_type'] as String? ?? '') == 'Storage')
                      .length,
                };

                return Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          children: [
                            _buildChip('Semua', allRecords.length,
                                _selectedFilter == 'Semua'),
                            _buildChip('Head', counts['Head']!,
                                _selectedFilter == 'Head'),
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
                            ? const Center(
                                child: Text("Tidak ada hasil yang cocok."))
                            : AnimationLimiter(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredRecords.length,
                                  itemBuilder: (context, index) {
                                    return AnimationConfiguration.staggeredList(
                                      position: index,
                                      duration:
                                          const Duration(milliseconds: 375),
                                      child: SlideAnimation(
                                        verticalOffset: 50.0,
                                        child: FadeInAnimation(
                                            child: _buildHistoryCard(
                                                filteredRecords[index])),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> record) {
    final unitCode = record['unit_code'] ?? 'N/A';
    final unitType = record['unit_type'] ?? '';
    final itemName =
        record['item_name'] ?? record['custom_title'] ?? 'Item tidak diketahui';
    final repairedBy = record['repaired_by'] ?? 'Tidak diketahui';
    final utcDate = DateTime.parse(record['repaired_at']);
    final localDate = utcDate.toLocal();
    final formattedDate = DateFormat('d MMM yyyy, HH:mm').format(localDate);
    final unitColor = _getColorForUnitType(unitType);

    IconData unitIcon = Icons.article;
    if (unitType == 'Head')
      unitIcon = Icons.fire_truck_rounded;
    else if (unitType == 'Chassis')
      unitIcon = Icons.miscellaneous_services_rounded;
    else if (unitType == 'Storage') unitIcon = Icons.inventory_2_rounded;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      MaintenanceHistoryDetailPage(record: record)));
        },
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
            backgroundColor: unitColor.withOpacity(0.1),
            child: Icon(unitIcon, color: unitColor)),
        title: Text(itemName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('Unit $unitCode \nOleh: $repairedBy'),
        trailing: Text(formattedDate,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ),
    );
  }
}
