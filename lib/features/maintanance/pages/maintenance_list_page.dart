// lib/features/maintenance/pages/maintenance_list_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:intl/intl.dart';
import 'maintenance_detail_page.dart';

class MaintenanceListPage extends StatefulWidget {
  const MaintenanceListPage({super.key});

  @override
  State<MaintenanceListPage> createState() => _MaintenanceListPageState();
}

class _MaintenanceListPageState extends State<MaintenanceListPage> {
  late Future<List<Map<String, dynamic>>> _maintenanceFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _maintenanceFuture = _fetchMaintenanceList();
    _searchController.addListener(() {
      if (mounted) setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchMaintenanceList() async {
    // [FIX] Select kolom baru 'unit_type' dan 'unique_unit_id'
    final response = await SupabaseManager.client
        .from('pending_repairs_view')
        .select('*, unit_type, unique_unit_id')
        .order('reported_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Widget _buildChip(String label, int count, bool isSelected) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ChoiceChip(
            label: Text('$label ($count)'),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) setState(() => _selectedFilter = label);
            },
            selectedColor: AppTheme.primary,
            labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold),
            backgroundColor: Colors.grey[200],
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color:
                        isSelected ? AppTheme.primary : Colors.grey.shade300)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Perlu Perbaikan"),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _maintenanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Terjadi error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.check_circle_outline,
                      size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text("Semua unit dalam kondisi baik!",
                      style: TextStyle(fontSize: 18, color: Colors.grey))
                ]));
          }

          final allItems = snapshot.data!;

          // [FIX] Mengelompokkan berdasarkan ID unik, bukan lagi kode unit
          final Map<String, List<Map<String, dynamic>>> groupedByUnit = {};
          for (var item in allItems) {
            final uniqueId = item['unique_unit_id'];
            if (uniqueId != null) {
              (groupedByUnit[uniqueId] ??= []).add(item);
            }
          }

          final List<Map<String, dynamic>> unitList =
              groupedByUnit.entries.map((entry) {
            final firstItem = entry.value.first;
            return {
              'unit_code': firstItem['unit_code'] ?? 'N/A',
              'items': entry.value,
              'item_count': entry.value.length,
              'latest_report': firstItem['reported_at'],
              'type': firstItem['unit_type'] ??
                  'Lainnya' // Menggunakan unit_type dari View
            };
          }).toList();

          final filteredList = unitList.where((unit) {
            final matchesFilter =
                _selectedFilter == 'Semua' || unit['type'] == _selectedFilter;
            final matchesSearch = unit['unit_code']
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
            return matchesFilter && matchesSearch;
          }).toList();

          final counts = {
            'Head': unitList.where((u) => u['type'] == 'Head').length,
            'Chassis': unitList.where((u) => u['type'] == 'Chassis').length,
            'Storage': unitList.where((u) => u['type'] == 'Storage').length,
          };

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari berdasarkan kode unit...',
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
              Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      _buildChip(
                          'Semua', unitList.length, _selectedFilter == 'Semua'),
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
                  onRefresh: () async {
                    setState(() {
                      _maintenanceFuture = _fetchMaintenanceList();
                    });
                  },
                  child: filteredList.isEmpty
                      ? const Center(child: Text("Tidak ada hasil yang cocok."))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final unit = filteredList[index];
                            final title = unit['unit_code'];
                            final itemCount = unit['item_count'];
                            final unitType = unit['type']; // Ambil tipe unit
                            final utcDate =
                                DateTime.parse(unit['latest_report']);
                            final localDate = utcDate.toLocal();
                            final formattedDate =
                                DateFormat('d MMMM yyyy, HH:mm')
                                    .format(localDate);

                            IconData icon = Icons.article;
                            if (unitType == 'Head')
                              icon = Icons.fire_truck_outlined;
                            else if (unitType == 'Chassis')
                              icon = Icons.miscellaneous_services_outlined;
                            else if (unitType == 'Storage')
                              icon = Icons.inventory_2_outlined;

                            return Card(
                              elevation: 2,
                              shadowColor: Colors.black.withOpacity(0.1),
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                leading: CircleAvatar(
                                    backgroundColor:
                                        Colors.red.withOpacity(0.1),
                                    child: Icon(icon, color: Colors.red[700])),
                                // [FIX] Tampilkan juga tipe unit agar jelas
                                title: Text("$title ($unitType)",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17)),
                                subtitle: Text(
                                    "$formattedDate\n($itemCount item perlu perbaikan)",
                                    style: TextStyle(color: Colors.red[900])),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 16),
                                onTap: () {
                                  Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  MaintenanceDetailPage(
                                                      unitCode: title,
                                                      items: unit['items'])))
                                      .then((value) => setState(() {
                                            _maintenanceFuture =
                                                _fetchMaintenanceList();
                                          }));
                                },
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
}
