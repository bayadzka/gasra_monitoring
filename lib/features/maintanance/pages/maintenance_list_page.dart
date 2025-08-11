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

  // Fungsi Fetch tidak berubah, karena kita hanya mengubah View di backend
  Future<List<Map<String, dynamic>>> _fetchMaintenanceList() async {
    final response = await SupabaseManager.client
        .from('pending_repairs_view')
        .select('*')
        .order('reported_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // BuildChip tidak berubah
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
                color: isSelected ? AppTheme.primary : Colors.grey.shade300)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Perlu Perbaikan"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
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
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final allItems = snapshot.data!;

          // [DIUBAH TOTAL] Logika pengelompokan dan filtering disederhanakan
          final Map<String, List<Map<String, dynamic>>> groupedByUnit = {};
          for (var item in allItems) {
            final unitCode = item['head_code'] ??
                item['chassis_code'] ??
                item['storage_code'] ??
                'Unknown';
            (groupedByUnit[unitCode] ??= []).add(item);
          }

          final List<Map<String, dynamic>> unitList =
              groupedByUnit.entries.map((entry) {
            final firstItem = entry.value.first;
            String unitType = '';
            if (firstItem['head_code'] != null)
              unitType = 'Head';
            else if (firstItem['chassis_code'] != null)
              unitType = 'Chassis';
            else if (firstItem['storage_code'] != null) unitType = 'Storage';

            return {
              'unit_code': entry.key,
              'items': entry.value,
              'item_count': entry.value.length,
              'latest_report': firstItem['reported_at'],
              'type': unitType
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
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final unit = filteredList[index];
                            final title = unit['unit_code'];
                            final itemCount = unit['item_count'];
                            final utcDate =
                                DateTime.parse(unit['latest_report']);
                            final localDate =
                                utcDate.toLocal(); // <-- Tambahkan baris ini
                            final formattedDate =
                                DateFormat('d MMMM yyyy, HH:mm')
                                    .format(localDate); // Gunakan localDate

                            IconData icon = Icons.article;
                            if (unit['type'] == 'Head')
                              icon = Icons.fire_truck_outlined;
                            else if (unit['type'] == 'Chassis')
                              icon = Icons.miscellaneous_services_outlined;
                            else if (unit['type'] == 'Storage')
                              icon = Icons.inventory_2_outlined;

                            return Card(
                              elevation: 2,
                              color: Colors.red[50],
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red.withOpacity(0.1),
                                  child: Icon(icon, color: Colors.red[700]),
                                ),
                                title: Text(title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17)),
                                subtitle: Text(
                                    "$formattedDate\n($itemCount item perlu perbaikan)",
                                    style: TextStyle(color: Colors.red[900])),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 16),
                                onTap: () {
                                  // [DIUBAH] Navigasi ke halaman detail yang sesuai
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MaintenanceDetailPage(
                                        unitCode: title,
                                        items: unit['items'],
                                      ),
                                    ),
                                  ).then((value) => setState(() {
                                        // Refresh list setelah kembali dari detail
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
