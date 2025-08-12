// lib/features/inspection/providers/chasis_inspection_provider.dart

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_inspection_provider.dart';

class ChassisInspectionProvider extends BaseInspectionProvider {
  String? selectedChassisCode;
  String? selectedChassisId;

  List<InspectionItem> allChassisItems = [];
  Map<String, List<InspectionItem>> groupedChassisItems = {};

  // [FIX] Tambahkan override ini, tapi arahkan ke groupedChassisItems
  @override
  Map<String, List<InspectionItem>> get groupedItems => groupedChassisItems;

  @override
  Map<String, InspectionItemResult> inspectionResults = {};
  @override
  String? get selectedVehicleCode => selectedChassisCode;
  @override
  List<InspectionItem> get allItems => allChassisItems;

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
          .eq('category', 'Chassis')
          .eq('subtype', subtype)
          .order('name', ascending: true); // Urutkan sementara berdasarkan nama

      allChassisItems = (response as List)
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

      // [FIX 2] Lakukan pengurutan kustom setelah data diambil
      _customSortItems();

      // [FIX 1] Lakukan pengelompokan berdasarkan page_title
      _groupItems();
      _initializeResults();
    } catch (e) {
      errorMessage = "Gagal mengambil data item: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // [BARU] Fungsi untuk mengurutkan item secara numerik
  void _customSortItems() {
    allChassisItems.sort((a, b) {
      // Fungsi untuk mengekstrak angka dari nama item
      int extractNumber(String text) {
        final match = RegExp(r'(\d+)').firstMatch(text);
        return match != null ? int.parse(match.group(1)!) : 0;
      }

      return extractNumber(a.name).compareTo(extractNumber(b.name));
    });
  }

  // [DIUBAH] Mengelompokkan item berdasarkan 'page_title' dari database
  void _groupItems() {
    groupedChassisItems.clear();
    for (var item in allChassisItems) {
      final groupKey = item.pageTitle ?? 'Lain-lain';
      (groupedChassisItems[groupKey] ??= []).add(item);
    }
  }

  void _initializeResults() {
    inspectionResults.clear();
    for (var item in allChassisItems) {
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
    final itemsToUpdate = groupedChassisItems[category] ?? [];
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
    final itemsToCheck = groupedChassisItems[category] ?? [];
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
    selectedChassisCode = code;
    selectedChassisId = id;
  }

  // Di dalam class ChassisInspectionProvider

  @override
  Future<void> submitInspection() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null || selectedChassisId == null) {
      throw Exception('User tidak login atau Chassis tidak dipilih.');
    }
    try {
      // [FIX] 'chassis_id' dikirim sebagai Angka (bigint)
      final inspectionData = {
        'chassis_id': int.tryParse(selectedChassisId!),
        'inspector_id': user.id,
        'tanggal': DateTime.now().toIso8601String(),
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
    selectedChassisCode = null;
    selectedChassisId = null;
    allChassisItems.clear();
    groupedChassisItems.clear();
    for (var result in inspectionResults.values) {
      result.notesController.removeListener(notifyListeners);
      result.notesController.dispose();
    }
    inspectionResults.clear();
    // Kita tidak panggil notifyListeners di sini agar tidak menyebabkan error saat dispose
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
