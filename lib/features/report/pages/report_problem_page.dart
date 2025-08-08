// lib/features/report/pages/report_problem_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

// [DIUBAH] Menambahkan titleController untuk judul masalah kustom
class ReportItem {
  final TextEditingController titleController = TextEditingController();
  String? selectedItemId; // Ini menjadi opsional
  final TextEditingController notesController = TextEditingController();
  File? problemImageFile;

  ReportItem({String? title, this.selectedItemId}) {
    titleController.text = title ?? '';
  }
}

class ReportProblemPage extends StatefulWidget {
  final String unitId;
  final String unitCode;
  final String unitCategory;
  final String unitSubtype;

  const ReportProblemPage({
    super.key,
    required this.unitId,
    required this.unitCode,
    required this.unitCategory,
    required this.unitSubtype,
  });

  @override
  State<ReportProblemPage> createState() => _ReportProblemPageState();
}

class _ReportProblemPageState extends State<ReportProblemPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  final List<ReportItem> _reportItems = [ReportItem()];
  DateTime? _selectedDeadline;
  late Future<List<Map<String, dynamic>>> _inspectionItemsFuture;

  @override
  void initState() {
    super.initState();
    _inspectionItemsFuture = _fetchInspectionItems();
    // Tidak perlu listener di sini karena kita menggunakan Form onChanged
  }

  @override
  void dispose() {
    for (var item in _reportItems) {
      item.titleController.dispose();
      item.notesController.dispose();
    }
    super.dispose();
  }

  // [DIUBAH] Logika validasi sekarang fokus pada judul
  bool _isFormValid() {
    if (_reportItems.isEmpty) return false;
    // Cek apakah setiap item setidaknya memiliki judul yang diisi
    return _reportItems
        .every((item) => item.titleController.text.trim().isNotEmpty);
  }

  Future<List<Map<String, dynamic>>> _fetchInspectionItems() async {
    // Fungsi ini sudah bagus, tidak perlu diubah
    String assetType = '';
    if (widget.unitCategory == 'heads')
      assetType = 'Head';
    else if (widget.unitCategory == 'chassis')
      assetType = 'Chassis';
    else if (widget.unitCategory == 'storages') assetType = 'Storage';

    if (assetType.isEmpty) return [];

    final response = await SupabaseManager.client
        .from('inspection_items')
        .select('id, name')
        .eq('category', assetType);
    // Note: Anda bisa menambahkan filter 'subtype' di sini jika diperlukan

    final List<Map<String, dynamic>> items =
        List<Map<String, dynamic>>.from(response);
    items.sort((a, b) => (a['name'] as String).compareTo(a['name']));
    return items;
  }

  void _addItem() {
    setState(() {
      _reportItems.add(ReportItem());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _reportItems[index].titleController.dispose();
      _reportItems[index].notesController.dispose();
      _reportItems.removeAt(index);
    });
  }

  // Fungsi _pickImage dan _showPhotoViewer tidak ada perubahan
  Future<void> _pickImage(ReportItem item) async {
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
          item.problemImageFile = File(pickedFile.path);
        });
      }
    }
  }

  void _showPhotoViewer(BuildContext context, File imageFile) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: FileImage(imageFile),
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

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  Future<void> _submitReport() async {
    // Trigger validasi form
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Harap isi semua kolom yang wajib diisi.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final supabase = SupabaseManager.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User tidak login");

      List<Map<String, dynamic>> payload = [];
      for (var item in _reportItems) {
        String? photoUrl;
        if (item.problemImageFile != null) {
          final imageFile = item.problemImageFile!;
          final fileName =
              'masalah/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

          // [DIUBAH] Ganti 'attachments' menjadi 'bukti-inspeksi'
          await supabase.storage
              .from('bukti-inspeksi')
              .upload(fileName, imageFile);
          photoUrl =
              supabase.storage.from('bukti-inspeksi').getPublicUrl(fileName);
        }
        final unitIdKey =
            '${widget.unitCategory.substring(0, widget.unitCategory.length - 1)}_id';

        // [DIUBAH] Payload sekarang menyertakan custom_title
        payload.add({
          'reported_by_id': userId,
          'custom_title': item.titleController.text.trim(), // Judul kustom
          'item_id': item.selectedItemId, // Item terkait (bisa null)
          'problem_notes': item.notesController.text.trim(),
          'deadline_date': _selectedDeadline?.toIso8601String(),
          unitIdKey: widget.unitId,
          'problem_photo_url': photoUrl,
          'status': 'reported', // Status awal
        });
      }

      await supabase
          .from('problem_reports')
          .insert(payload); // Pastikan tabel 'problem_reports'
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Laporan berhasil dikirim!'),
            backgroundColor: Colors.green),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal mengirim laporan: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lapor Masalah: ${widget.unitCode}"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _inspectionItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // Bahkan jika tidak ada item, form tetap bisa digunakan
          final inspectionItems = snapshot.data ?? [];

          return Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                ..._reportItems.asMap().entries.map((entry) {
                  int idx = entry.key;
                  ReportItem item = entry.value;
                  return _buildReportItemCard(idx, item, inspectionItems);
                }),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Tambah Item Masalah"),
                  onPressed: _addItem,
                ),
                const Divider(height: 32),
                _buildDeadlinePicker(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.send),
          label: const Text("Kirim Laporan"),
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          onPressed: _isSubmitting || !_isFormValid() ? null : _submitReport,
        ),
      ),
    );
  }

  // [DIUBAH TOTAL] Kartu item laporan sekarang lebih fleksibel
  Widget _buildReportItemCard(int index, ReportItem reportItem,
      List<Map<String, dynamic>> inspectionItems) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Item Masalah #${index + 1}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                if (_reportItems.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeItem(index),
                  )
              ],
            ),
            const Divider(),
            TextFormField(
              controller: reportItem.titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Masalah',
                hintText: 'Contoh: Aki mati, Ban bocor, dll.',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Judul wajib diisi'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: reportItem.selectedItemId,
              isExpanded: true,
              hint: const Text('Pilih item terkait (Opsional)'),
              items: inspectionItems.map((item) {
                return DropdownMenuItem<String>(
                  value: item['id'].toString(), // Pastikan value adalah String
                  child: Text(item['name'], overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  reportItem.selectedItemId = value;
                });
              },
              // validator dihapus karena opsional
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: reportItem.notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Detail Keterangan',
                border: OutlineInputBorder(),
              ),
              // validator bisa ditambahkan jika detail juga wajib
            ),
            const SizedBox(height: 12),
            if (reportItem.problemImageFile != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  InkWell(
                    onTap: () =>
                        _showPhotoViewer(context, reportItem.problemImageFile!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        reportItem.problemImageFile!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
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
                          setState(() => reportItem.problemImageFile = null),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: Icon(reportItem.problemImageFile == null
                  ? Icons.add_a_photo_outlined
                  : Icons.change_circle_outlined),
              label: Text(reportItem.problemImageFile == null
                  ? "Tambah Foto Bukti"
                  : "Ganti Foto"),
              onPressed: () => _pickImage(reportItem),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildDeadlinePicker tidak ada perubahan
  Widget _buildDeadlinePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Estimasi Penyelesaian",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDeadline(context),
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDeadline == null
                      ? 'Pilih tanggal'
                      : DateFormat('d MMMM yyyy').format(_selectedDeadline!),
                ),
                const Icon(Icons.calendar_today),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
