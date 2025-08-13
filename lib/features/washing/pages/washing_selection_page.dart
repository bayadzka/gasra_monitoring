// lib/features/washing/pages/washing_selection_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class WashingSelectionPage extends StatefulWidget {
  final List<Map<String, dynamic>>? initialSelection;

  const WashingSelectionPage({
    super.key,
    this.initialSelection,
  });

  @override
  State<WashingSelectionPage> createState() => _WashingSelectionPageState();
}

class _WashingSelectionPageState extends State<WashingSelectionPage> {
  late Future<List<Map<String, dynamic>>> _storagesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late List<Map<String, dynamic>> _selectedStorages;

  @override
  void initState() {
    super.initState();
    _storagesFuture = _fetchStorages();
    _selectedStorages =
        List<Map<String, dynamic>>.from(widget.initialSelection ?? []);
    _searchController.addListener(() {
      if (mounted) setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchStorages() async {
    // Pastikan RPC 'get_storages_with_last_washed_date' ada di Supabase Anda
    final response =
        await SupabaseManager.client.rpc('get_storages_with_last_washed_date');
    final allStorages = List<Map<String, dynamic>>.from(response ?? []);

    allStorages.sort((a, b) {
      final int numA = int.tryParse(a['storage_code'] ?? '99999') ?? 99999;
      final int numB = int.tryParse(b['storage_code'] ?? '99999') ?? 99999;
      return numA.compareTo(numB);
    });

    return allStorages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Pilih Unit Storage"),
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
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white, // Warna putih agar kontras
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _storagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Terjadi error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Tidak ada data storage."));
                }

                final allStorages = snapshot.data!;
                final filteredStorages = allStorages.where((storage) {
                  return storage['storage_code']
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
                            child: _buildUnitTile(filteredStorages[index]),
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
      bottomNavigationBar: Container(
        color: AppTheme.background,
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: Text("Pilih (${_selectedStorages.length})"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () {
            Navigator.pop(context, _selectedStorages);
          },
        ),
      ),
    );
  }

  Widget _buildUnitTile(Map<String, dynamic> storage) {
    final isSelected = _selectedStorages.any((s) => s['id'] == storage['id']);
    final lastWashed = storage['last_washed_at'];
    String subtitleText = 'Belum pernah dicuci';
    Color subtitleColor = Colors.red;

    if (lastWashed != null) {
      final lastWashedDate = DateTime.parse(lastWashed).toLocal();
      final difference = DateTime.now().difference(lastWashedDate);
      subtitleText =
          'Terakhir dicuci: ${DateFormat('d MMM yyyy').format(lastWashedDate)}';

      if (difference.inDays <= 7) {
        subtitleColor = Colors.green;
      }
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: CheckboxListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        activeColor: AppTheme.primary,
        title: Text(storage['storage_code'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitleText,
          style: TextStyle(color: subtitleColor, fontSize: 13),
        ),
        value: isSelected,
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              _selectedStorages.add(storage);
            } else {
              _selectedStorages.removeWhere((s) => s['id'] == storage['id']);
            }
          });
        },
      ),
    );
  }
}
