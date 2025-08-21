// lib/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';
import 'package:gasra_monitoring/features/maintanance/pages/maintenance_list_page.dart';
import 'package:gasra_monitoring/features/maintanance/pages/maintanance_history_page.dart'; // [BARU] Import halaman riwayat perbaikan
import 'package:gasra_monitoring/main.dart';

class NotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotifications.initialize(settings);
  }

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission();
    await _initializeLocalNotifications();
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  // [DIUBAH] Fungsi ini sekarang menangani 2 jenis notifikasi
  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print("Notifikasi di-klik!");
      print("Data: ${message.data}");
    }

    // Cek apakah ini notifikasi masalah baru
    if (message.data['report_id'] != null ||
        message.data['result_id'] != null) {
      // Arahkan pengguna ke halaman "Perlu Perbaikan"
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MaintenanceListPage()),
        (route) => route.isFirst,
      );
    }
    // [BARU] Cek apakah ini notifikasi perbaikan selesai
    else if (message.data['maintenance_id'] != null) {
      // Arahkan pengguna ke halaman "Riwayat Perbaikan"
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MaintenanceHistoryPage()),
        (route) => route.isFirst,
      );
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage? message) async {
    if (message == null || message.notification == null) {
      if (kDebugMode) {
        print('Pesan foreground diterima tapi tidak ada notifikasi.');
      }
      return;
    }

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Channel ini digunakan untuk notifikasi penting.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _localNotifications.show(
      message.hashCode,
      message.notification!.title,
      message.notification!.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@drawable/ic_notification',
        ),
      ),
    );
  }

  Future<void> getTokenAndSave() async {
    final fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken == null) return;
    await _saveTokenToDatabase(fcmToken);
  }

  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final userId = SupabaseManager.client.auth.currentUser?.id;
      if (userId == null) return;

      await SupabaseManager.client
          .from('profiles')
          .update({'fcm_token': token}).eq('id', userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error saat menyimpan FCM token: $e');
      }
    }
  }
}
