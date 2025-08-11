// lib/features/history/history_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/core/widgets/empty_state_widget.dart';
import 'package:intl/intl.dart';
import 'history_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Map<String, dynamic>>> _inspectionsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _inspectionsFuture = _fetchInspections();
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

  Future<List<Map<String, dynamic>>> _fetchInspections() async {
    final supabase = SupabaseManager.client;

    // [DIUBAH] Menghapus filter user dan menambahkan join ke tabel profiles
    final response = await supabase
        .from('inspections')
        .select(
            '*, heads!inspections_head_id_fkey(head_code), chassis!inspections_chassis_id_fkey(chassis_code), storages!inspections_storage_id_fkey(storage_code), profiles(name)')
        // .eq('inspector_id', userId) // <-- BARIS INI DIHAPUS
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Widget _buildChip tidak ada perubahan
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
        title: const Text("Riwayat Inspeksi"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _inspectionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Terjadi error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.search_off,
              message: "Belum ada riwayat inspeksi.",
            );
          }

          final allInspections = snapshot.data!;

          // Logika filter tidak ada perubahan
          final categoryFiltered = allInspections.where((inspection) {
            if (_selectedFilter == 'Semua') return true;
            if (_selectedFilter == 'Head') return inspection['heads'] != null;
            if (_selectedFilter == 'Chassis')
              return inspection['chassis'] != null;
            if (_selectedFilter == 'Storage')
              return inspection['storages'] != null;
            return false;
          }).toList();

          final filteredInspections = categoryFiltered.where((inspection) {
            String title = '';
            if (inspection['heads'] != null)
              title = inspection['heads']['head_code'];
            else if (inspection['chassis'] != null)
              title = inspection['chassis']['chassis_code'];
            else if (inspection['storages'] != null)
              title = inspection['storages']['storage_code'];
            return title.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          final counts = {
            'Head': allInspections.where((i) => i['heads'] != null).length,
            'Chassis': allInspections.where((i) => i['chassis'] != null).length,
            'Storage':
                allInspections.where((i) => i['storages'] != null).length,
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
                      _buildChip('Semua', allInspections.length,
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
                child: filteredInspections.isEmpty
                    ? const Center(child: Text("Tidak ada hasil yang cocok."))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        itemCount: filteredInspections.length,
                        itemBuilder: (context, index) {
                          final inspection = filteredInspections[index];
                          String title = 'Inspeksi';
                          IconData icon = Icons.article;
                          if (inspection['heads'] != null) {
                            title = inspection['heads']['head_code'];
                            icon = Icons.fire_truck_outlined;
                          } else if (inspection['chassis'] != null) {
                            title = inspection['chassis']['chassis_code'];
                            icon = Icons.miscellaneous_services_outlined;
                          } else if (inspection['storages'] != null) {
                            title = inspection['storages']['storage_code'];
                            icon = Icons.inventory_2_outlined;
                          }
                          final utcDate =
                              DateTime.parse(inspection['created_at']);
                          final localDate = utcDate.toLocal();
                          final formattedDate = DateFormat('d MMMM yyyy, HH:mm')
                              .format(localDate);

                          // [DIUBAH] Ambil nama penginspeksi
                          final inspectorName = (inspection['profiles'] != null)
                              ? inspection['profiles']['name']
                              : 'N/A';

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppTheme.primary.withOpacity(0.1),
                                child: Icon(icon, color: AppTheme.primary),
                              ),
                              title: Text(title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17)),
                              // [DIUBAH] Tampilkan nama penginspeksi di subtitle
                              subtitle: Text(
                                'Oleh: $inspectorName • $formattedDate',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HistoryDetailPage(
                                      inspectionId: inspection['id'],
                                      inspectionCode: title,
                                      // [DIUBAH] Kirim nama penginspeksi ke halaman detail
                                      inspectorName: inspectorName,
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
          );
        },
      ),
    );
  }
}
