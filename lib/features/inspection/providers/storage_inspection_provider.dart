// lib/features/inspection/providers/storage_inspection_provider.dart

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_inspection_provider.dart'; // Import kontrak base

class StorageInspectionProvider extends BaseInspectionProvider {
  String? selectedStorageCode;
  String? selectedStorageId;

  // [DIUBAH] Ganti nama variabel ke "storage"
  List<InspectionItem> allStorageItems = [];
  Map<String, List<InspectionItem>> groupedStorageItems = {};
  @override
  Map<String, InspectionItemResult> inspectionResults = {};
  @override
  String? get selectedVehicleCode => selectedStorageCode;
  @override
  List<InspectionItem> get allItems => allStorageItems;

  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  // [IMPLEMENTASI KONTRAK]
  @override
  Map<String, List<InspectionItem>> get groupedItems => groupedStorageItems;

  @override
  Future<void> fetchInspectionItems({required String subtype}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('inspection_items')
          .select()
          .eq('category', 'Storage')
          // [DIUBAH] subtype tidak lagi dari parameter, tapi nilai pasti 'Umum'
          .eq('subtype', 'Umum')
          .order('name', ascending: true);

      allStorageItems = (response as List)
          .map((item) => InspectionItem(
                id: item['id'],
                name: item['name'],
                standard: item['standard'],
                category: item['category'],
                subtype: item['subtype'],
                pageTitle: item['page_title'],
              ))
          .toList();

      _initializeResults();
    } catch (e) {
      errorMessage = "Gagal mengambil data item: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _initializeResults() {
    inspectionResults.clear();
    for (var item in allStorageItems) {
      final result = InspectionItemResult();
      result.notesController.addListener(notifyListeners);
      inspectionResults[item.id] = result;
    }
  }

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
    final itemsToUpdate = groupedStorageItems[category] ?? [];
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
    // Validasi semua item sekaligus
    if (allStorageItems.isEmpty) return true;
    return allStorageItems.every((item) {
      final result = inspectionResults[item.id];
      if (result?.condition == null) return false;
      if (result?.condition == 'tidak_baik' &&
          result!.notesController.text.trim().isEmpty) return false;
      return true;
    });
  }

  @override
  void updateVehicleSelection(String? code, String? id) {
    selectedStorageCode = code;
    selectedStorageId = id;
  }

  // Di dalam class StorageInspectionProvider

  @override
  Future<void> submitInspection() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null || selectedStorageId == null) {
      throw Exception('User tidak login atau Storage tidak dipilih.');
    }
    try {
      // [FIX] 'storage_id' dikirim sebagai Angka (bigint)
      final inspectionData = {
        'storage_id': int.tryParse(selectedStorageId!),
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
    selectedStorageCode = null;
    selectedStorageId = null;
    allStorageItems.clear();
    groupedStorageItems.clear();
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
