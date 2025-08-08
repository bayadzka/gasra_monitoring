// lib/features/auth/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';

class AuthProvider extends ChangeNotifier {
  String? _userRole;
  String? _userName; // [BARU] Tambahkan variabel untuk nama
  bool _isLoading = true;

  int _inspeksiBulanIni = 0;
  int _perluPerbaikan = 0;
  bool _isStatsLoading = true;

  String? get userRole => _userRole;
  String? get userName => _userName; // [BARU] Getter untuk nama
  bool get isLoading => _isLoading;

  int get inspeksiBulanIni => _inspeksiBulanIni;
  int get perluPerbaikan => _perluPerbaikan;
  bool get isStatsLoading => _isStatsLoading;

  Future<void> fetchDashboardStats() async {
    _isStatsLoading = true;
    notifyListeners();
    try {
      final result = await SupabaseManager.client.rpc('get_dashboard_stats');
      _inspeksiBulanIni = result['inspeksi_bulan_ini'] ?? 0;
      _perluPerbaikan = result['perlu_perbaikan'] ?? 0;
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      _inspeksiBulanIni = 0;
      _perluPerbaikan = 0;
    } finally {
      _isStatsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = SupabaseManager.client.auth.currentUser;
      if (user != null) {
        final response = await SupabaseManager.client
            .from('profiles')
            .select('role, name') // [DIUBAH] Ambil role dan name
            .eq('id', user.id)
            .single();
        _userRole = response['role'] as String?;
        _userName = response['name'] as String?; // [BARU] Simpan nama

        await fetchDashboardStats();
      }
    } catch (e) {
      _userRole = null;
      _userName = 'Pengguna'; // [DIUBAH] Beri nama default jika gagal
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
