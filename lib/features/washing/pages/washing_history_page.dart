// lib/features/washing/pages/washing_history_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/washing/pages/washing_detail_page.dart';
import 'package:intl/intl.dart';

class WashingHistoryPage extends StatefulWidget {
  const WashingHistoryPage({super.key});

  @override
  State<WashingHistoryPage> createState() => _WashingHistoryPageState();
}

class _WashingHistoryPageState extends State<WashingHistoryPage> {
  late Future<List<Map<String, dynamic>>> _historyFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchWashingHistory();
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

  Future<List<Map<String, dynamic>>> _fetchWashingHistory() async {
    final supabase = SupabaseManager.client;

    // [FIX] Mengubah join menjadi LEFT JOIN agar semua data tampil
    final response = await supabase
        .from('washing_history')
        .select(
            '*, washed_by:profiles!left(name), storage:storages!left(id, storage_code)')
        .order('washed_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Pencucian"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Terjadi error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada riwayat pencucian.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final allRecords = snapshot.data!;
          final filteredRecords = allRecords.where((record) {
            // Pastikan null check di sini
            final storageCode = record['storage']?['storage_code'] ?? '';
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
                    hintText: 'Cari berdasarkan kode storage...',
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
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _historyFuture = _fetchWashingHistory();
                    });
                  },
                  child: filteredRecords.isEmpty
                      ? const Center(child: Text("Tidak ada hasil yang cocok."))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          itemCount: filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = filteredRecords[index];
                            final storageData = record['storage'];

                            // Jika storageData null, tampilkan pesan error atau kode default
                            final storageCode = storageData?['storage_code'] ??
                                'Unit Tidak Ditemukan';
                            final storageId =
                                storageData?['id']?.toString() ?? '';

                            final washedBy = record['washed_by']?['name'] ??
                                'Tidak diketahui';
                            final notes = record['notes']?.isNotEmpty == true
                                ? record['notes']
                                : 'Tidak ada catatan.';

                            final utcDate = DateTime.parse(record['washed_at']);
                            final localDate = utcDate.toLocal();
                            final formattedDate =
                                DateFormat('d MMMM yyyy, HH:mm')
                                    .format(localDate);

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              child: ListTile(
                                onTap: () {
                                  if (storageId.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => WashingDetailPage(
                                          storageId: storageId,
                                          storageCode: storageCode,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                contentPadding: const EdgeInsets.all(16.0),
                                title: Text("Storage: $storageCode",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(height: 16),
                                    _buildInfoRow(Icons.person_outline,
                                        "Dicuci Oleh:", washedBy),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(Icons.calendar_today_outlined,
                                        "Tanggal:", formattedDate),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(Icons.note_alt_outlined,
                                        "Catatan:", notes),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text("$label ", style: TextStyle(color: Colors.grey[700])),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }
}
