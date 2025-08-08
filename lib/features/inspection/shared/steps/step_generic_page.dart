// lib/features/inspection/shared/steps/step_generic_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gasra_monitoring/features/inspection/providers/base_inspection_provider.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

class StepGenericPage extends StatelessWidget {
  final String category;
  const StepGenericPage({super.key, required this.category});

  // Fungsi helper untuk memilih gambar
  Future<void> _pickImage(
      BuildContext context, String itemIdOrReportItem) async {
    final provider = context
        .read<BaseInspectionProvider>(); // Sesuaikan dengan provider Anda
    final picker = ImagePicker();

    // Tampilkan dialog pilihan antara Kamera dan Galeri
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
        // Logika ini disesuaikan tergantung halaman
        // Contoh untuk step_generic_page.dart:
        provider.setProblemImage(itemIdOrReportItem, File(pickedFile.path));
      }
    }
  }

  // Tambahkan fungsi ini di halaman yang membutuhkan
  void _showPhotoViewer(BuildContext context, File imageFile) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: FileImage(imageFile), // Gunakan FileImage
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BaseInspectionProvider>();
    final items = provider.groupedItems[category] ?? [];
    final standardText = items.isNotEmpty ? items.first.standard : null;
    final imagePath = items.isNotEmpty ? items.first.layoutImagePath : null;

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text(category, style: AppTextStyles.title)),
            TextButton(
              onPressed: () {
                context
                    .read<BaseInspectionProvider>()
                    .setAllConditionsToBaik(category);
              },
              child: const Text("Baik Semua"),
            )
          ],
        ),
        const SizedBox(height: 16),
        if (imagePath != null && imagePath.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        if (standardText != null && standardText.isNotEmpty)
          Card(
            color: AppTheme.primary.withOpacity(0.05),
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                "Standardisasi: $standardText",
                style:
                    const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ),
          ),
        const Divider(),
        if (items.isEmpty)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Tidak ada item inspeksi untuk kategori ini."),
          ))
        else
          ...items.map((item) {
            return _buildInspectionRow(context, item);
          }),
      ],
    );
  }

  Widget _buildInspectionRow(BuildContext context, InspectionItem item) {
    return Consumer<BaseInspectionProvider>(
      builder: (context, provider, child) {
        final result = provider.inspectionResults[item.id]!;
        final isKeteranganWajib = result.condition == 'tidak_baik';
        final isKeteranganKosong = result.notesController.text.trim().isEmpty;
        final String? errorText =
            (isKeteranganWajib && isKeteranganKosong) ? 'Wajib diisi' : null;

        final isSpecialCategory = category == 'Surat Kendaraan' ||
            category == 'Tools & Safety' ||
            category == 'Tools & Apar';
        final String positiveLabel = isSpecialCategory ? 'Ada' : 'Baik';
        final String negativeLabel =
            isSpecialCategory ? 'Tidak Ada' : 'Tidak Baik';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildConditionButton(context, positiveLabel, 'baik',
                      result.condition, item.id),
                  const SizedBox(width: 8),
                  _buildConditionButton(context, negativeLabel, 'tidak_baik',
                      result.condition, item.id),
                ],
              ),
              const SizedBox(height: 12),
              if (result.condition == 'tidak_baik')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: result.notesController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                          hintText: 'Keterangan (Wajib diisi)...',
                          errorText: errorText,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8))),
                    ),
                    const SizedBox(height: 12),
                    if (result.problemImageFile != null)
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          InkWell(
                            onTap: () => _showPhotoViewer(
                                context, result.problemImageFile!),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                result.problemImageFile!,
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
                              onPressed: () {
                                // Panggil provider untuk menghapus foto (mengosongkan file)
                                provider.setProblemImage(item.id, null);
                              },
                            ),
                          ),
                        ],
                      ),
                    if (result.problemImageFile == null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text("Tambah Foto Bukti"),
                        onPressed: () => _pickImage(context, item.id),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: BorderSide(
                                color: AppTheme.primary.withOpacity(0.5))),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConditionButton(BuildContext context, String title, String value,
      String? currentValue, String itemId) {
    final provider = context.read<BaseInspectionProvider>();
    final isSelected = currentValue == value;

    return Expanded(
      child: OutlinedButton(
        onPressed: () => provider.updateCondition(itemId, value),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: isSelected
              ? (value == 'baik' ? Colors.green : Colors.red)
              : Colors.transparent,
          side: BorderSide(
            color: isSelected ? Colors.transparent : Colors.grey.shade400,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
