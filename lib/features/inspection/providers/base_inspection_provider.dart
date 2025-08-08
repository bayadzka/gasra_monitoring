// lib/features/inspection/providers/base_inspection_provider.dart

import 'package:flutter/material.dart';
import 'dart:io';

// Model ini kita pindahkan ke sini agar bisa diakses bersama
class InspectionItem {
  final String id;
  final String name;
  final String? standard;
  final String category;
  final String? subtype;
  final String? pageTitle;
  final String? layoutImagePath;

  InspectionItem({
    required this.id,
    required this.name,
    this.standard,
    required this.category,
    this.subtype,
    this.pageTitle,
    this.layoutImagePath,
  });
}

// Model ini juga kita pindahkan ke sini
class InspectionItemResult {
  String? condition;
  final TextEditingController notesController = TextEditingController();
  File? problemImageFile;
  InspectionItemResult({this.condition});
}

abstract class BaseInspectionProvider extends ChangeNotifier {
  // Properti
  Map<String, List<InspectionItem>> get groupedItems;
  Map<String, InspectionItemResult> get inspectionResults;
  bool get isLoading;
  String? get errorMessage;
  String? get selectedVehicleCode;
  List<InspectionItem> get allItems;

  // Metode
  void updateCondition(String itemId, String condition);
  void setAllConditionsToBaik(String category);
  bool isStepValid(String category);

  // [FIX] Tambahkan metode-metode ini ke dalam kontrak
  Future<void> fetchInspectionItems({required String subtype});
  void updateVehicleSelection(String? code, String? id);
  Future<void> submitInspection();
  void clearAllData();
  void setProblemImage(String itemId, File? imageFile);
}
