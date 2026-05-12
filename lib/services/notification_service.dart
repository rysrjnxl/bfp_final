import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bfp_final/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling background alert: ${message.messageId}");
}

class NotificationService {
  static const _channelId = 'high_importance_channel';
  static const _channelName = 'Fire Alert Notifications';
  static const _channelDesc =
      'This channel is used for high-priority BFP fire alerts.';
  static const _sound = RawResourceAndroidNotificationSound('alarm');

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _createChannel();
    await _initLocalNotifications();
    await _requestPermissions();
    await _subscribeToTopic();
    _listenForegroundMessages();
  }

  Future<void> _createChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: _sound,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _requestPermissions() async {
    // 1. Request FCM notification permission
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      sound: true,
      badge: true,
    );

    // 2. Request SYSTEM_ALERT_WINDOW permission for overlay
    final bool hasPermission =
        await FlutterOverlayWindow.isPermissionGranted();
    if (!hasPermission) {
      await FlutterOverlayWindow.requestPermission();
    }
  }

  Future<void> _subscribeToTopic() async {
    await FirebaseMessaging.instance.subscribeToTopic('station_alerts');
  }

  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      final android = message.notification?.android;
      final data = message.data;

      // Show local notification as fallback
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              sound: _sound,
              enableVibration: true,
              fullScreenIntent: true,
            ),
          ),
        );
      }

      // Show overlay on top of any app
      await _showOverlay(data);
    });
  }

  Future<void> _showOverlay(Map<String, dynamic> data) async {
    try {
      final bool hasPermission =
          await FlutterOverlayWindow.isPermissionGranted();
      if (!hasPermission) return;

      // Open the overlay window
      await FlutterOverlayWindow.showOverlay(
        height: 500,
        width: WindowSize.matchParent,
        alignment: OverlayAlignment.center,
        flag: OverlayFlag.defaultFlag,
        enableDrag: false,
        positionGravity: PositionGravity.auto,
      );

      // Small delay to let the overlay window initialize before sending data
      await Future.delayed(const Duration(milliseconds: 300));

      // Send alarm data to the overlay
      await FlutterOverlayWindow.shareData({
        'fireType': data['fireType'] ?? 'Fire Alert',
        'location': data['location'] ?? 'Unknown Location',
        'note': data['note'] ?? '',
        'triggeredBy': data['triggeredBy'] ?? '',
        'lat': data['lat'] != null ? double.tryParse(data['lat'].toString()) : null,
        'lng': data['lng'] != null ? double.tryParse(data['lng'].toString()) : null,
      });
    } catch (e) {
      debugPrint('Overlay error: $e');
    }
  }
}