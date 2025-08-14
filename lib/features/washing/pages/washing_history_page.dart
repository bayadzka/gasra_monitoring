// lib/features/washing/pages/washing_history_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/washing/pages/washing_detail_page.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
      if (mounted) setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchWashingHistory() async {
    final supabase = SupabaseManager.client;
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Riwayat Pencucian"),
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
                hintText: 'Cari berdasarkan kode storage...',
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
                    child: Text("Belum ada riwayat pencucian.",
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                  );
                }

                final allRecords = snapshot.data!;
                final filteredRecords = allRecords.where((record) {
                  final storageCode = record['storage']?['storage_code'] ?? '';
                  return storageCode
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredRecords.isEmpty) {
                  return const Center(
                      child: Text("Tidak ada hasil yang cocok."));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _historyFuture = _fetchWashingHistory();
                    });
                  },
                  child: AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredRecords.length,
                      itemBuilder: (context, index) {
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildWashingCard(filteredRecords[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWashingCard(Map<String, dynamic> record) {
    final storageData = record['storage'];
    final storageCode = storageData?['storage_code'] ?? 'Unit Dihapus';
    final storageId = storageData?['id']?.toString() ?? '';
    final washedBy = record['washed_by']?['name'] ?? 'Tidak diketahui';
    final utcDate = DateTime.parse(record['washed_at']);
    final localDate = utcDate.toLocal();
    final formattedDate = DateFormat('d MMMM yyyy, HH:mm').format(localDate);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          child: const Icon(Icons.inventory_2_rounded, color: AppTheme.primary),
        ),
        title: Text(storageCode,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: Text('Oleh: $washedBy • $formattedDate'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
