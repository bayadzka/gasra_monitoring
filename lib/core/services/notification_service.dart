// lib/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  // Buat instance dari Firebase Messaging
  final _firebaseMessaging = FirebaseMessaging.instance;

  // Fungsi untuk inisialisasi notifikasi
  Future<void> initialize() async {
    // 1. Meminta izin dari pengguna (penting untuk iOS & Android 13+)
    await _firebaseMessaging.requestPermission();

    // 2. Mengambil FCM Token unik untuk perangkat ini
    final fcmToken = await _firebaseMessaging.getToken();
    if (kDebugMode) {
      print('====================================');
      print('FCM Token: $fcmToken');
      print('====================================');
    }
    // Nanti kita akan simpan token ini ke Supabase

    // 3. Menyiapkan listener untuk notifikasi saat aplikasi sedang dibuka (foreground)
    FirebaseMessaging.onMessage.listen(_handleMessage);
  }

  // Fungsi untuk menangani notifikasi yang masuk saat aplikasi terbuka
  void _handleMessage(RemoteMessage? message) {
    if (message == null) return;

    if (kDebugMode) {
      print('Pesan notifikasi diterima di foreground!');
      print('Judul: ${message.notification?.title}');
      print('Isi: ${message.notification?.body}');
      print('Data: ${message.data}');
    }
    // Di sini Anda bisa menampilkan dialog atau snackbar jika diperlukan
  }
}
