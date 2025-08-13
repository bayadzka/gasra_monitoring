// lib/features/washing/pages/washing_log_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/dialog_helper.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/washing/pages/washing_selection_page.dart';
import 'package:intl/intl.dart';

class WashingLogPage extends StatefulWidget {
  const WashingLogPage({super.key});

  @override
  State<WashingLogPage> createState() => _WashingLogPageState();
}

class _WashingLogPageState extends State<WashingLogPage> {
  List<Map<String, dynamic>> _selectedStorages = [];
  DateTime _displayDate = DateTime.now();
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _displayDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _displayDate) {
      setState(() {
        _displayDate = picked;
      });
    }
  }

  Future<void> _submitWashingLog() async {
    if (_selectedStorages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu unit storage.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = SupabaseManager.client.auth.currentUser?.id;
      if (userId == null) throw Exception("User tidak login.");

      final payload = _selectedStorages.map((storage) {
        return {
          'storage_id': storage['id'],
          'washed_by_id': userId,
          'notes': _notesController.text,
        };
      }).toList();

      await SupabaseManager.client.from('washing_history').insert(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan pencucian berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _removeStorage(Map<String, dynamic> storageToRemove) {
    setState(() {
      _selectedStorages.removeWhere((s) => s['id'] == storageToRemove['id']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;
          showExitConfirmationDialog(context);
        },
        child: Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text("Catat Pencucian Storage"),
            backgroundColor: AppTheme.background,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionTitle("Unit Dicuci"),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_task_outlined),
                label: Text(_selectedStorages.isEmpty
                    ? "Pilih Unit Storage"
                    : "${_selectedStorages.length} unit dipilih"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final result =
                      await Navigator.push<List<Map<String, dynamic>>>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => WashingSelectionPage(
                              initialSelection: _selectedStorages,
                            )),
                  );
                  if (result != null) {
                    setState(() {
                      _selectedStorages = result;
                    });
                  }
                },
              ),
              if (_selectedStorages.isNotEmpty)
                Container(
                  height: 150,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12)),
                  child: ListView(
                    children: _selectedStorages.map((storage) {
                      return ListTile(
                        title: Text(storage['storage_code']),
                        dense: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.red, size: 20),
                          onPressed: () => _removeStorage(storage),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 24),
              _buildSectionTitle("Tanggal Pencucian"),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('d MMMM yyyy').format(_displayDate)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("Catatan (Opsional)"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Masukkan catatan jika ada...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            color: AppTheme.background,
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save_alt_outlined),
              label: const Text("Konfirmasi & Simpan"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isSubmitting ? null : _submitWashingLog,
            ),
          ),
        ));
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
  }
}
