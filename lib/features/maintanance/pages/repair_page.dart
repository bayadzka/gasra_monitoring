// lib/features/maintenance/pages/repair_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/dialog_helper.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

class RepairPage extends StatefulWidget {
  final Map<String, dynamic> item;
  const RepairPage({super.key, required this.item});

  @override
  State<RepairPage> createState() => _RepairPageState();
}

class _RepairPageState extends State<RepairPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  File? _repairImageFile;
  bool _isSubmitting = false;

  // Fungsi _showPhotoViewer, _pickImage tidak ada perubahan
  void _showPhotoViewer(BuildContext context,
      {String? imageUrl, File? imageFile}) {
    ImageProvider? imageProvider;
    if (imageUrl != null) {
      imageProvider = NetworkImage(imageUrl);
    } else if (imageFile != null) {
      imageProvider = FileImage(imageFile);
    } else {
      return;
    }
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: imageProvider,
              initialScale: PhotoViewComputedScale.contained,
            ),
            Positioned(
              top: 16,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Buka Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? pickedFile =
          await picker.pickImage(source: source, imageQuality: 50);
      if (pickedFile != null) {
        setState(() {
          _repairImageFile = File(pickedFile.path);
        });
      }
    }
  }

  // [DIUBAH TOTAL] Logika submit disesuaikan dengan 'pending_repairs_view'
  Future<void> _submitRepair() async {
    if (!_formKey.currentState!.validate()) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi"),
        content:
            const Text("Anda yakin ingin menyimpan catatan perbaikan ini?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Batal")),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Ya, Simpan")),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final userId = SupabaseManager.client.auth.currentUser?.id;
      if (userId == null) throw Exception("User tidak login.");

      String? repairPhotoUrl;
      if (_repairImageFile != null) {
        final fileName =
            'perbaikan/repair_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // [DIUBAH] Ganti 'attachments' menjadi 'bukti-inspeksi'
        await SupabaseManager.client.storage
            .from('bukti-inspeksi')
            .upload(fileName, _repairImageFile!);
        repairPhotoUrl = SupabaseManager.client.storage
            .from('bukti-inspeksi')
            .getPublicUrl(fileName);
      }
      final reportType = widget.item['report_type'];
      final problemId =
          widget.item['result_id']; // [FIX] Menggunakan 'result_id' dari View

      if (reportType == 'inspection') {
        // Jika sumbernya dari inspeksi reguler
        await SupabaseManager.client.from('maintenance_records').insert({
          'inspection_result_id': problemId,
          'repaired_by_id': userId,
          'notes': _notesController.text,
          'repair_photo_url': repairPhotoUrl,
        });
      } else if (reportType == 'quick_report') {
        // Jika sumbernya dari laporan masalah cepat
        await SupabaseManager.client.from('maintenance_records').insert({
          'problem_report_id': problemId,
          'repaired_by_id': userId,
          'notes': _notesController.text,
          'repair_photo_url': repairPhotoUrl,
        });

        await SupabaseManager.client
            .from('problem_reports')
            .update({'status': 'diperbaiki'}).eq('id', problemId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Catatan perbaikan berhasil disimpan!'),
            backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true); // Kirim 'true' untuk menandakan berhasil
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemName = widget.item['custom_title'] ??
        widget.item['item_name'] ??
        'Item tidak diketahui';
    final problemNotes =
        widget.item['problem_notes'] ?? 'Tidak ada keterangan.';
    final problemPhotoUrl = widget.item['problem_photo_url'];

    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;
          showExitConfirmationDialog(context);
        },
        child: Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(itemName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.background,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionTitle("Detail Masalah"),
                if (problemPhotoUrl != null && problemPhotoUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                    child: InkWell(
                      onTap: () =>
                          _showPhotoViewer(context, imageUrl: problemPhotoUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(problemPhotoUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                    ),
                  ),
                Text(problemNotes, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                _buildSectionTitle("Form Perbaikan"),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: "Catatan Perbaikan",
                    hintText: "Contoh: Baut sudah dikencangkan",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Catatan tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 16),
                if (_repairImageFile != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      InkWell(
                        onTap: () {
                          if (_repairImageFile != null) {
                            _showPhotoViewer(context,
                                imageFile: _repairImageFile!);
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_repairImageFile!,
                              height: 100, width: 100, fit: BoxFit.cover),
                        ),
                      ),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black.withOpacity(0.6),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 14),
                          onPressed: () =>
                              setState(() => _repairImageFile = null),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: Icon(_repairImageFile == null
                      ? Icons.add_a_photo_outlined
                      : Icons.change_circle_outlined),
                  label: Text(_repairImageFile == null
                      ? "Upload Foto Perbaikan"
                      : "Ganti Foto"),
                  onPressed: _pickImage,
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            color: AppTheme.background,
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Simpan Catatan Perbaikan"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              onPressed: _isSubmitting ? null : _submitRepair,
            ),
          ),
        ));
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: AppTextStyles.subtitle),
    );
  }
}
