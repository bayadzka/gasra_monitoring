// lib/features/history/history_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/core/widgets/empty_state_widget.dart';
import 'package:gasra_monitoring/features/history/history_detail_page.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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

  // LOGIKA ANDA: Fungsi ini tidak diubah
  Future<List<Map<String, dynamic>>> _fetchInspections() async {
    final supabase = SupabaseManager.client;
    final response = await supabase
        .from('inspections')
        .select(
            '*, heads!inspections_head_id_fkey(head_code), chassis!inspections_chassis_id_fkey(chassis_code), storages!inspections_storage_id_fkey(storage_code), profiles(name)')
        .order('tanggal', ascending: false); // [FIX] Menggunakan 'tanggal'

    return List<Map<String, dynamic>>.from(response);
  }

  // [UI HELPER BARU] Fungsi untuk menentukan warna berdasarkan tipe unit
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

  // [UI HELPER] Widget Chip tidak diubah
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
        backgroundColor: Colors.white,
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
    // [UI DIUBAH TOTAL]
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Riwayat Inspeksi"),
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
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _inspectionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Terjadi error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.history_toggle_off,
                    message: "Belum ada riwayat inspeksi.",
                  );
                }

                final allInspections = snapshot.data!;

                // LOGIKA ANDA: Tidak diubah
                final filteredByType = allInspections.where((inspection) {
                  if (_selectedFilter == 'Semua') return true;
                  if (_selectedFilter == 'Head')
                    return inspection['heads'] != null;
                  if (_selectedFilter == 'Chassis')
                    return inspection['chassis'] != null;
                  if (_selectedFilter == 'Storage')
                    return inspection['storages'] != null;
                  return false;
                }).toList();

                final filteredInspections = filteredByType.where((inspection) {
                  String title = '';
                  if (inspection['heads'] != null)
                    title = inspection['heads']['head_code'];
                  else if (inspection['chassis'] != null)
                    title = inspection['chassis']['chassis_code'];
                  else if (inspection['storages'] != null)
                    title = inspection['storages']['storage_code'];
                  return title
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                }).toList();

                final counts = {
                  'Head':
                      allInspections.where((i) => i['heads'] != null).length,
                  'Chassis':
                      allInspections.where((i) => i['chassis'] != null).length,
                  'Storage':
                      allInspections.where((i) => i['storages'] != null).length,
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
                            _buildChip('Semua', allInspections.length,
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
                        onRefresh: () async {
                          setState(() {
                            _inspectionsFuture = _fetchInspections();
                          });
                        },
                        child: filteredInspections.isEmpty
                            ? const Center(
                                child: Text("Tidak ada hasil yang cocok."))
                            : AnimationLimiter(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredInspections.length,
                                  itemBuilder: (context, index) {
                                    return AnimationConfiguration.staggeredList(
                                      position: index,
                                      duration:
                                          const Duration(milliseconds: 375),
                                      child: SlideAnimation(
                                        verticalOffset: 50.0,
                                        child: FadeInAnimation(
                                            child: _buildHistoryCard(
                                                filteredInspections[index])),
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

  Widget _buildHistoryCard(Map<String, dynamic> inspection) {
    String title = 'N/A';
    String type = 'Lainnya';
    IconData icon = Icons.article;

    if (inspection['heads'] != null) {
      title = inspection['heads']['head_code'];
      type = 'Head';
      icon = Icons.fire_truck_rounded;
    } else if (inspection['chassis'] != null) {
      title = inspection['chassis']['chassis_code'];
      type = 'Chassis';
      icon = Icons.miscellaneous_services_rounded;
    } else if (inspection['storages'] != null) {
      title = inspection['storages']['storage_code'];
      type = 'Storage';
      icon = Icons.inventory_2_rounded;
    }

    // LOGIKA ANDA: Tidak diubah
    final utcDate = DateTime.parse(inspection['tanggal']);
    final localDate = utcDate.toLocal();
    final formattedDate = DateFormat('d MMMM yyyy, HH:mm').format(localDate);
    final inspectorName = inspection['profiles']?['name'] ?? 'N/A';
    final unitColor = _getColorForUnitType(type);

    // [UI DIUBAH] Menggunakan desain kartu baru
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryDetailPage(
                  inspectionId: inspection['id'],
                  inspectionCode: title,
                  inspectorName: inspectorName,
                ),
              ));
        },
        child: Row(
          children: [
            Container(width: 8, color: unitColor),
            Expanded(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: CircleAvatar(
                    backgroundColor: unitColor.withOpacity(0.1),
                    child: Icon(icon, color: unitColor)),
                title: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 17)),
                subtitle: Text('Oleh: $inspectorName • $formattedDate'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
