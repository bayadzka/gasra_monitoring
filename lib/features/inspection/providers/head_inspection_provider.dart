// lib/features/inspection/providers/head_inspection_provider.dart

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_inspection_provider.dart';

class HeadInspectionProvider extends BaseInspectionProvider {
  String? selectedHeadCode;
  String? selectedHeadId;

  List<InspectionItem> allHeadItems = [];
  Map<String, List<InspectionItem>> groupedHeadItems = {};

  @override
  Map<String, List<InspectionItem>> get groupedItems => groupedHeadItems;
  @override
  Map<String, InspectionItemResult> inspectionResults = {};
  @override
  String? get selectedVehicleCode => selectedHeadCode;
  @override
  List<InspectionItem> get allItems => allHeadItems;
  @override
  bool isLoading = false;
  @override
  String? errorMessage;

  @override
  Future<void> fetchInspectionItems({required String subtype}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('inspection_items')
          .select()
          .eq('category', 'Head')
          .eq('subtype', subtype)
          .order('name', ascending: true);

      allHeadItems = (response as List)
          .map((item) => InspectionItem(
                id: item['id'],
                name: item['name'],
                standard: item['standard'],
                category: item['category'],
                subtype: item['subtype'],
                pageTitle: item['page_title'],
                layoutImagePath: item['layout_image_path'],
              ))
          .toList();

      _customSortItems();
      _groupItems();
      _initializeResults();
    } catch (e) {
      errorMessage = "Gagal mengambil data item: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _customSortItems() {
    allHeadItems.sort((a, b) {
      int extractNumber(String text) {
        final match = RegExp(r'(\d+)').firstMatch(text);
        return match != null ? int.parse(match.group(1)!) : 0;
      }

      return extractNumber(a.name).compareTo(extractNumber(b.name));
    });
  }

  void _groupItems() {
    groupedHeadItems.clear();
    for (var item in allHeadItems) {
      final groupKey = item.pageTitle ?? 'Lain-lain';
      (groupedHeadItems[groupKey] ??= []).add(item);
    }
  }

  void _initializeResults() {
    inspectionResults.clear();
    for (var item in allHeadItems) {
      final result = InspectionItemResult();
      result.notesController.addListener(notifyListeners);
      inspectionResults[item.id] = result;
    }
  }

  // [DIUBAH] Fungsi ini sekarang membersihkan data saat kondisi "baik"
  @override
  void updateCondition(String itemId, String condition) {
    if (inspectionResults.containsKey(itemId)) {
      inspectionResults[itemId]!.condition = condition;

      // [FIX] Jika kondisi diubah menjadi "baik", hapus keterangan dan foto
      if (condition == 'baik') {
        inspectionResults[itemId]!.notesController.clear();
        inspectionResults[itemId]!.problemImageFile = null;
      }

      notifyListeners();
    }
  }

  // [DIUBAH] Fungsi ini sekarang juga membersihkan data
  @override
  void setAllConditionsToBaik(String category) {
    final itemsToUpdate = groupedHeadItems[category] ?? [];
    for (var item in itemsToUpdate) {
      if (inspectionResults.containsKey(item.id)) {
        inspectionResults[item.id]!.condition = 'baik';

        // [FIX] Hapus juga keterangan dan foto saat "Baik Semua" ditekan
        inspectionResults[item.id]!.notesController.clear();
        inspectionResults[item.id]!.problemImageFile = null;
      }
    }
    notifyListeners();
  }

  @override
  bool isStepValid(String category) {
    final itemsToCheck = groupedHeadItems[category] ?? [];
    if (itemsToCheck.isEmpty) return true;
    return itemsToCheck.every((item) {
      final result = inspectionResults[item.id];
      if (result?.condition == null) return false;
      if (result?.condition == 'tidak_baik' &&
          result!.notesController.text.trim().isEmpty) return false;
      return true;
    });
  }

  @override
  void updateVehicleSelection(String? code, String? id) {
    selectedHeadCode = code;
    selectedHeadId = id;
  }

  @override
  Future<void> submitInspection() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null || selectedHeadId == null) {
      throw Exception('User tidak login atau Head tidak dipilih.');
    }
    try {
      final inspectionData = {
        'head_id': selectedHeadId,
        'inspector_id': user.id,
        'tanggal': DateTime.now().toUtc().toIso8601String(),
      };

      final insertedInspection = await supabase
          .from('inspections')
          .insert(inspectionData)
          .select('id')
          .single();
      final inspectionId = insertedInspection['id'];

      List<Map<String, dynamic>> allResultsPayload = [];
      for (var entry in inspectionResults.entries) {
        final itemId = entry.key;
        final result = entry.value;
        String? photoUrl;

        if (result.condition == 'tidak_baik' &&
            result.problemImageFile != null) {
          final imageFile = result.problemImageFile!;
          final fileName =
              'masalah/${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await supabase.storage
              .from('bukti-inspeksi')
              .upload(fileName, imageFile);
          photoUrl =
              supabase.storage.from('bukti-inspeksi').getPublicUrl(fileName);
        }

        if (result.condition != null) {
          allResultsPayload.add({
            'inspection_id': inspectionId,
            'item_id': itemId,
            'kondisi': result.condition,
            'keterangan': result.notesController.text,
            'problem_photo_url': photoUrl,
          });
        }
      }

      if (allResultsPayload.isNotEmpty) {
        await supabase.from('inspection_results').insert(allResultsPayload);
      }
    } catch (e) {
      throw Exception('Gagal mengirim data: $e');
    }
  }

  @override
  void clearAllData() {
    selectedHeadCode = null;
    selectedHeadId = null;
    allHeadItems.clear();
    groupedHeadItems.clear();
    for (var result in inspectionResults.values) {
      result.notesController.removeListener(notifyListeners);
      result.notesController.dispose();
    }
    inspectionResults.clear();
  }

  @override
  void dispose() {
    clearAllData();
    super.dispose();
  }

  @override
  void setProblemImage(String itemId, File? imageFile) {
    if (inspectionResults.containsKey(itemId)) {
      inspectionResults[itemId]!.problemImageFile = imageFile;
      notifyListeners();
    }
  }
}
