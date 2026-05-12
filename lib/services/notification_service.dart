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

  // Must re-initialize plugin — background runs in a separate isolate
  final plugin = FlutterLocalNotificationsPlugin();

  await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'high_importance_channel',
        'Fire Alert Notifications',
        description: 'High-priority BFP fire alerts.',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alarm'),
        enableVibration: true,
      ));

  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  final data = message.data;
  await plugin.show(
    0,
    '🚨 FIRE ALERT: ${data['fireType'] ?? 'Unknown Fire'}',
    '📍 ${data['location'] ?? 'Unknown Location'}',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'Fire Alert Notifications',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alarm'),
        enableVibration: true,
        fullScreenIntent: true, // ← acts as overlay when app is closed
      ),
    ),
  );
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
      final data = message.data;

      // Always show local notification for foreground
      flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '🚨 FIRE ALERT: ${data['fireType'] ?? 'Unknown'}',
        '📍 ${data['location'] ?? 'Unknown Location'}',
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
      await _showOverlay(data);
    });
  }

  Future<void> _showOverlay(Map<String, dynamic> data) async {
    try {
      final bool hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      if (!hasPermission) {
        await FlutterOverlayWindow.requestPermission();
        return; // don't proceed if just now requesting
      }

      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      await FlutterOverlayWindow.showOverlay(
        height: 620,                        // ✅ match home.dart height
        width: WindowSize.matchParent,
        alignment: OverlayAlignment.center,
        flag: OverlayFlag.defaultFlag,
        enableDrag: false,
        positionGravity: PositionGravity.auto,
      );

      await Future.delayed(const Duration(milliseconds: 800)); // ✅ was 300ms — too short

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