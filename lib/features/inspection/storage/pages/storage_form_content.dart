// lib/features/inspection/storage/pages/storage_form_content.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/features/inspection/providers/base_inspection_provider.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class StorageFormContent extends StatelessWidget {
  const StorageFormContent({super.key});
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
    // Digunakan watch agar UI bisa update saat "Baik Semua" ditekan
    final provider = context.watch<BaseInspectionProvider>();
    final items = (provider as dynamic).allStorageItems;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
                child: Text('Checklist Storage', style: AppTextStyles.title)),
            TextButton(
              onPressed: () => provider.setAllConditionsToBaik('Umum'),
              child: const Text("Baik Semua"),
            )
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        ...items
            .map<Widget>((item) => _buildInspectionRow(context, item))
            .toList(),
      ],
    );
  }

  Widget _buildInspectionRow(BuildContext context, InspectionItem item) {
    return Consumer<BaseInspectionProvider>(
      builder: (context, provider, child) {
        final result = provider.inspectionResults[item.id]!;
        final isKeteranganWajib = result.condition == 'tidak_baik';
        final isKeteranganKosong = result.notesController.text.trim().isEmpty;
        final errorText =
            (isKeteranganWajib && isKeteranganKosong) ? 'Wajib diisi' : null;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              if (item.standard != null && item.standard!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "Standar: ${item.standard!}",
                    style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700]),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildConditionButton(
                      context, 'Baik', 'baik', result.condition, item.id),
                  const SizedBox(width: 8),
                  _buildConditionButton(context, 'Tidak Baik', 'tidak_baik',
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
                      decoration: InputDecoration(
                          hintText: 'Keterangan (Wajib diisi)...',
                          errorText: errorText,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8))),
                    ),
                    const SizedBox(height: 12),

                    // [DIUBAH] Bungkus preview dan tombol dalam Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Preview Gambar
                        if (result.problemImageFile != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Stack(
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
                                  backgroundColor:
                                      Colors.black.withOpacity(0.6),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.close,
                                        color: Colors.white, size: 14),
                                    onPressed: () =>
                                        provider.setProblemImage(item.id, null),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Tombol Tambah/Ganti Foto
                        OutlinedButton.icon(
                          icon: Icon(result.problemImageFile == null
                              ? Icons.add_a_photo_outlined
                              : Icons.change_circle_outlined),
                          label: Text(result.problemImageFile == null
                              ? "Tambah Foto"
                              : "Ganti"),
                          onPressed: () => _pickImage(context, item.id),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: BorderSide(
                                  color: AppTheme.primary.withOpacity(0.5))),
                        ),
                      ],
                    )
                  ],
                ),
              const Divider(height: 24),
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
