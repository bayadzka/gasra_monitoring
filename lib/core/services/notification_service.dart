// lib/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gasra_monitoring/core/services/supabase_config.dart';

class NotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(settings);
  }

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission();
    await _initializeLocalNotifications();
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _handleForegroundMessage(RemoteMessage? message) async {
    // [FIX] Tambahkan null check yang lebih kuat di awal
    if (message == null || message.notification == null) {
      if (kDebugMode) {
        print('Pesan foreground diterima tapi tidak ada notifikasi.');
      }
      return;
    }

    if (kDebugMode) {
      print('Pesan notifikasi diterima di foreground!');
      print('Judul: ${message.notification!.title}');
      print('Isi: ${message.notification!.body}');
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
