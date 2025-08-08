// lib/features/washing/pages/washing_selection_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:intl/intl.dart'; // [FIX] Tambahkan import ini

class WashingSelectionPage extends StatefulWidget {
  const WashingSelectionPage({super.key});

  @override
  State<WashingSelectionPage> createState() => _WashingSelectionPageState();
}

class _WashingSelectionPageState extends State<WashingSelectionPage> {
  late Future<List<Map<String, dynamic>>> _storagesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<Map<String, dynamic>> _selectedStorages = [];

  @override
  void initState() {
    super.initState();
    _storagesFuture = _fetchStorages();
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
    final response =
        await SupabaseManager.client.rpc('get_storages_with_last_washed_date');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Unit Storage"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _storagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Terjadi error: ${snapshot.error}"));
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

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari kode storage...',
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
                child: ListView.builder(
                  itemCount: filteredStorages.length,
                  itemBuilder: (context, index) {
                    final storage = filteredStorages[index];
                    final isSelected =
                        _selectedStorages.any((s) => s['id'] == storage['id']);

                    final lastWashed = storage['last_washed_at'];
                    String subtitleText = 'Belum pernah dicuci';
                    Color subtitleColor = Colors.red;

                    if (lastWashed != null) {
                      final lastWashedDate = DateTime.parse(lastWashed);
                      final difference =
                          DateTime.now().difference(lastWashedDate);
                      subtitleText =
                          'Terakhir dicuci: ${DateFormat('d MMM yyyy').format(lastWashedDate)}';

                      if (difference.inDays <= 7) {
                        subtitleColor = Colors.green;
                      }
                    }

                    return CheckboxListTile(
                      title: Text(storage['storage_code']),
                      subtitle: Text(
                        subtitleText,
                        style: TextStyle(color: subtitleColor, fontSize: 12),
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedStorages.add(storage);
                          } else {
                            _selectedStorages
                                .removeWhere((s) => s['id'] == storage['id']);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: Text("Pilih (${_selectedStorages.length})"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: _selectedStorages.isNotEmpty
              ? () {
                  Navigator.pop(context, _selectedStorages);
                }
              : null,
        ),
      ),
    );
  }
}
