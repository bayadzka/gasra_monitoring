// lib/features/inspection/shared/steps/step_review_page.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/features/inspection/providers/base_inspection_provider.dart';
import 'package:gasra_monitoring/core/theme.dart';
import 'package:gasra_monitoring/features/inspection/storage/pages/storage_form_content.dart';
import 'package:provider/provider.dart';
import 'step_generic_page.dart';

class StepReviewPage extends StatefulWidget {
  const StepReviewPage({super.key});

  @override
  State<StepReviewPage> createState() => _StepReviewPageState();
}

class _StepReviewPageState extends State<StepReviewPage> {
  @override
  // Di dalam file step_review_page.dart

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BaseInspectionProvider>();
    final grouped = provider.groupedItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Ringkasan Inspeksi", style: AppTextStyles.title),
          const SizedBox(height: 8),
          Text("Kode Unit: ${provider.selectedVehicleCode ?? ''}",
              style: AppTextStyles.subtitle),
          const SizedBox(height: 16),

          // [FIX] Logika baru yang lebih aman dan cerdas
          if (grouped.keys.isNotEmpty)
            // Jika ada grup (Head/Chassis), tampilkan per grup
            ...grouped.keys.map((category) {
              final itemsInCategory = grouped[category] ?? [];
              return _buildSection(context, category, itemsInCategory);
            })
          else
            // Jika tidak ada grup (Storage), tampilkan semua item dalam satu seksi
            _buildSection(context, 'Checklist Storage', provider.allItems),
        ],
      ),
    );
  }

  // Di dalam file step_review_page.dart

  Widget _buildSection(
      BuildContext context, String title, List<InspectionItem> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(title,
                        style: AppTextStyles.subtitle.copyWith(fontSize: 18))),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppTheme.primary),
                  tooltip: 'Edit',
                  // [FIX] Logika onPressed disederhanakan agar selalu memanggil dialog
                  onPressed: () async {
                    await _showEditDialog(context, title);
                    setState(() {});
                  },
                ),
              ],
            ),
            const Divider(),
            // ... sisa kode Table biarkan apa adanya ...
            Table(
              columnWidths: const {
                0: FlexColumnWidth(4),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(4),
              },
              border: TableBorder.all(color: Colors.grey.shade300, width: 1),
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Colors.black12),
                  children: [
                    Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Item',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Kondisi',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Keterangan',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                ...items.map((item) {
                  final result = context
                      .read<BaseInspectionProvider>()
                      .inspectionResults[item.id];
                  return TableRow(
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(item.name)),
                      Center(
                          child: result?.condition == null
                              ? Container()
                              : (result?.condition == 'baik')
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : const Icon(Icons.cancel,
                                      color: Colors.red)),
                      Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(result?.notesController.text ?? '')),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, String title) async {
    final provider = context.read<BaseInspectionProvider>();

    // [FIX] Tentukan konten dialog secara dinamis
    Widget dialogContent;
    if (title == 'Checklist Storage') {
      dialogContent = const StorageFormContent();
    } else {
      dialogContent = StepGenericPage(category: title);
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ChangeNotifierProvider.value(
            value: provider,
            child: Consumer<BaseInspectionProvider>(
              builder: (context, validationProvider, child) {
                final isSaveButtonEnabled =
                    validationProvider.isStepValid(title);
                return AlertDialog(
                  title: Text("Edit: $title"),
                  content: SizedBox(
                      width: double.maxFinite,
                      child: dialogContent), // Gunakan konten dinamis
                  actions: [
                    ElevatedButton(
                      onPressed: isSaveButtonEnabled
                          ? () => Navigator.of(dialogContext).pop()
                          : null,
                      child: const Text("Simpan Perubahan"),
                    ),
                  ],
                );
              },
            ));
      },
    );
  }
}
