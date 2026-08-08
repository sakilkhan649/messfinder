import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:mess_finder/features/notifications/models/app_notification_model.dart';

/// ─── Background message handler (top-level function, required by FCM) ────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this runs.
  debugPrint('📨 [FCM] Background message: ${message.messageId}');
}

/// ─── Core Notification Service ───────────────────────────────────────────────
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _androidChannel = AndroidNotificationChannel(
    'messfinder_high_importance',
    'MessFinder Notifications',
    description: 'Important notifications from MessFinder',
    importance: Importance.high,
    playSound: true,
  );

  // ── Initialize ──────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    // 1. Request permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Setup local notifications for foreground
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 3. Create Android high-importance channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // 4. Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 6. Check if app was opened from a terminated notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    debugPrint('✅ [FCM] NotificationService initialized');
  }

  // ── Foreground Message Handler ───────────────────────────────────────────────
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 [FCM] Foreground message: ${message.notification?.title}');
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'MessFinder',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  // ── Show Local Notification (when app is open) ────────────────────────────
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // ── Notification Tap Handler ─────────────────────────────────────────────
  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'] ?? '';
    debugPrint('🔔 [FCM] Notification tapped, type: $type');
    // Navigation can be added based on type
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 [FCM] Local notification tapped: ${response.payload}');
  }

  // ── Get & Save FCM Token ─────────────────────────────────────────────────
  Future<String?> getToken() async {
    try {
      final token = await _fcm.getToken();
      debugPrint('🔑 [FCM] Token: $token');
      return token;
    } catch (e) {
      debugPrint('❌ [FCM] Token error: $e');
      return null;
    }
  }

  Future<void> saveTokenToFirestore(String uid) async {
    try {
      final token = await getToken();
      if (token != null) {
        await _firestore.collection('users').doc(uid).update({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ [FCM] Token saved for user: $uid');
      }
    } catch (e) {
      debugPrint('❌ [FCM] Token save error: $e');
    }
  }

  // ── Topic Subscriptions ──────────────────────────────────────────────────
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    debugPrint('✅ [FCM] Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    debugPrint('✅ [FCM] Unsubscribed from topic: $topic');
  }

  // ── Store notification in Firestore (in-app notification center) ──────────
  Future<void> storeNotification(AppNotificationModel notification) async {
    try {
      await _firestore
          .collection('notifications')
          .add(notification.toMap());
    } catch (e) {
      debugPrint('❌ [FCM] Store notification error: $e');
    }
  }

  // ── Send Push Notification via FCM HTTP Legacy API ───────────────────────
  /// [token] — receiver's FCM token
  /// [title] — notification title
  /// [body] — notification body
  /// [data] — extra data payload
  Future<void> sendPushToToken({
    required String token,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    // Get FCM Server Key from Firestore config (stored securely)
    try {
      final configDoc = await _firestore
          .collection('app_config')
          .doc('fcm')
          .get();
      final serverKey = configDoc.data()?['serverKey'] ?? '';
      if (serverKey.isEmpty) {
        debugPrint('⚠️ [FCM] No server key found in Firestore config');
        return;
      }

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'data': data,
          'priority': 'high',
          'android': {
            'notification': {
              'channel_id': 'messfinder_high_importance',
              'priority': 'high',
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [FCM] Push sent successfully');
      } else {
        debugPrint('❌ [FCM] Push failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [FCM] sendPushToToken error: $e');
    }
  }

  /// Send push to a topic (e.g., 'bachelors', 'landlords', 'all_users')
  Future<void> sendPushToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    await sendPushToToken(
      token: '/topics/$topic',
      title: title,
      body: body,
      data: data,
    );
  }

  /// Helper: Get FCM token of a specific user from Firestore
  Future<String?> getUserToken(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['fcmToken'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Helper: Send push + store in Firestore notification center
  Future<void> sendAndStore({
    required String receiverUid,
    required String title,
    required String body,
    required NotificationType type,
    String? senderUid,
    String? relatedId,
    Map<String, String> extraData = const {},
  }) async {
    // 1. Store in Firestore (in-app notification center)
    await storeNotification(AppNotificationModel(
      id: '',
      title: title,
      body: body,
      type: type,
      receiverUid: receiverUid,
      senderUid: senderUid,
      relatedId: relatedId,
      createdAt: DateTime.now(),
    ));

    // 2. Send push notification
    final token = await getUserToken(receiverUid);
    if (token != null && token.isNotEmpty) {
      await sendPushToToken(
        token: token,
        title: title,
        body: body,
        data: <String, String>{
          'type': type.name,
          ...extraData,
          'relatedId': ?relatedId,
        },
      );
    }
  }

  // ── Mark notification as read ────────────────────────────────────────────
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead(String uid) async {
    final batch = _firestore.batch();
    final query = await _firestore
        .collection('notifications')
        .where('receiverUid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Stream of notifications for a user ──────────────────────────────────
  Stream<List<AppNotificationModel>> getNotificationsStream(String uid) {
    return _firestore
        .collection('notifications')
        .where('receiverUid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => AppNotificationModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        })
        .handleError((error) {
          debugPrint('❌ Notifications stream error: $error');
        });
  }

  // ── Unread count stream ──────────────────────────────────────────────────
  Stream<int> getUnreadCountStream(String uid) {
    return _firestore
        .collection('notifications')
        .where('receiverUid', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
            .where((doc) => (doc.data()['isRead'] ?? false) == false)
            .length)
        .handleError((error) {
          debugPrint('❌ Unread count stream error: $error');
        });
  }
}
