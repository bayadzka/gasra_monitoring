// lib/features/washing/pages/washing_detail_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:intl/intl.dart';

class WashingDetailPage extends StatefulWidget {
  final String storageId;
  final String storageCode;

  const WashingDetailPage({
    super.key,
    required this.storageId,
    required this.storageCode,
  });

  @override
  State<WashingDetailPage> createState() => _WashingDetailPageState();
}

class _WashingDetailPageState extends State<WashingDetailPage> {
  late Future<List<Map<String, dynamic>>> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _fetchWashingDetails();
  }

  Future<List<Map<String, dynamic>>> _fetchWashingDetails() async {
    final response = await SupabaseManager.client
        .from('washing_history')
        .select('*, washed_by:profiles(name)')
        .eq('storage_id', widget.storageId)
        .order('washed_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Riwayat: ${widget.storageCode}"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Terjadi error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Belum ada riwayat pencucian untuk unit ini."),
            );
          }

          final records = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final washedBy =
                  record['washed_by']?['name'] ?? 'Tidak diketahui';
              final notes = record['notes']?.isNotEmpty == true
                  ? record['notes']
                  : 'Tidak ada catatan.';
              final date = DateTime.parse(record['washed_at']);
              final formattedDate =
                  DateFormat('d MMMM yyyy, HH:mm').format(date);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.calendar_today_outlined, "Tanggal:",
                          formattedDate),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                          Icons.person_outline, "Dicuci Oleh:", washedBy),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.note_alt_outlined, "Catatan:", notes),
                    ],
                  ),
                ),
              );
            },
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
