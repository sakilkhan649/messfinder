import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mess_finder/features/auth/controllers/auth_controller.dart';
import 'package:mess_finder/features/chat/controllers/chat_controller.dart';
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
    'messfinder_high_importance_v2',
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

    // 1. Never show notification if sender is the current logged-in user
    final senderUid = message.data['senderUid'] ?? message.data['sender_uid'];
    final myUid = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().currentUser.value?.uid
        : null;

    if (myUid != null && senderUid != null && senderUid.toString().trim() == myUid.toString().trim()) {
      debugPrint('🚫 [FCM] Suppressed self-sent foreground notification');
      return;
    }

    // 2. If user is currently looking at this active chat room, don't show an overlapping banner
    final chatRoomId = message.data['chatRoomId'] ?? message.data['relatedId'];
    if (Get.isRegistered<ChatController>()) {
      final chatCtrl = Get.find<ChatController>();
      if (chatCtrl.currentActiveChatId != null &&
          chatRoomId != null &&
          chatCtrl.currentActiveChatId == chatRoomId) {
        debugPrint('🚫 [FCM] Suppressed notification for currently active chat room');
        return;
      }
    }

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
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          color: const Color(0xFF059669),
          playSound: true,
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

  // ── Show Call Notification ───────────────────────────────────────────────
  Future<void> showCallNotification({
    required String callerName,
    required bool isVideo,
    String? payload,
  }) async {
    await _showLocalNotification(
      id: 9999,
      title: isVideo ? '📹 Incoming Video Call' : '📞 Incoming Audio Call',
      body: '$callerName is calling you...',
      payload: payload,
    );
  }

  Future<void> cancelCallNotification() async {
    try {
      await _localNotifications.cancel(9999);
    } catch (e) {
      debugPrint('Cancel notification error: $e');
    }
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
        await _firestore.collection('users').doc(uid).set({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
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

  /// Send push via Vercel Backend (FCM HTTP v1 API)
  Future<void> sendPush({
    required String receiverUid,
    required String title,
    required String body,
    String type = '',
    String relatedId = '',
  }) async {
    try {
      final vercelUrl = 'https://vercelbackend-ruby.vercel.app/api/send';
      
      final response = await http.post(
        Uri.parse(vercelUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'receiverUid': receiverUid,
          'title': title,
          'body': body,
          'type': type,
          'relatedId': relatedId,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Vercel] Push sent successfully');
      } else {
        debugPrint('❌ [Vercel] Push failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [Vercel] sendPush error: $e');
    }
  }

  /// Helper: Send push to a topic
  Future<void> sendPushToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    await sendPush(
      receiverUid: '/topics/$topic',
      title: title,
      body: body,
      type: data['type'] ?? '',
      relatedId: data['relatedId'] ?? '',
    );
  }

  /// Helper: Store in Firestore notification center and send via Vercel
  Future<void> sendAndStore({
    required String receiverUid,
    required String title,
    required String body,
    required NotificationType type,
    String? senderUid,
    String? relatedId,
    Map<String, String> extraData = const {},
  }) async {
    // 0. Prevent self-notifications (sender should never notify themselves)
    if (senderUid != null && senderUid.isNotEmpty && senderUid == receiverUid) {
      debugPrint('ℹ️ [NotificationService] Skipping self-notification for uid: $senderUid');
      return;
    }

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

    // 2. Send push notification via Vercel API
    await sendPush(
      receiverUid: receiverUid,
      title: title,
      body: body,
      type: type.name,
      relatedId: relatedId ?? '',
    );
  }

  // ── Mark notification as read ────────────────────────────────────────────
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  Future<void> markAllAsRead(String uid, {String? role}) async {
    final batch = _firestore.batch();
    final targets = <String>[uid, 'all'];
    if (role != null && role.isNotEmpty && role.toLowerCase() != 'all') {
      targets.add(role.toLowerCase());
    }
    final query = await _firestore
        .collection('notifications')
        .where('receiverUid', whereIn: targets)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in query.docs) {
      final sender = doc.data()['senderUid']?.toString();
      if (sender == uid) continue; // Skip self actions
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteAllNotifications(String uid, {String? role}) async {
    final batch = _firestore.batch();
    final targets = <String>[uid, 'all'];
    if (role != null && role.isNotEmpty && role.toLowerCase() != 'all') {
      targets.add(role.toLowerCase());
    }
    final query = await _firestore
        .collection('notifications')
        .where('receiverUid', whereIn: targets)
        .get();
    for (final doc in query.docs) {
      final sender = doc.data()['senderUid']?.toString();
      if (sender == uid) continue;
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ── Stream of notifications for a user ──────────────────────────────────
  Stream<List<AppNotificationModel>> getNotificationsStream(String uid, {String? role}) {
    final targets = <String>[uid, 'all'];
    if (role != null && role.isNotEmpty && role.toLowerCase() != 'all') {
      targets.add(role.toLowerCase());
    }
    return _firestore
        .collection('notifications')
        .where('receiverUid', whereIn: targets)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => AppNotificationModel.fromMap(doc.data(), doc.id))
              .where((item) => item.senderUid != uid) // Never show actions performed by myself
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        })
        .handleError((error) {
          debugPrint('❌ Notifications stream error: $error');
        });
  }

  // ── Unread count stream ──────────────────────────────────────────────────
  Stream<int> getUnreadCountStream(String uid, {String? role}) {
    final targets = <String>[uid, 'all'];
    if (role != null && role.isNotEmpty && role.toLowerCase() != 'all') {
      targets.add(role.toLowerCase());
    }
    return _firestore
        .collection('notifications')
        .where('receiverUid', whereIn: targets)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppNotificationModel.fromMap(doc.data(), doc.id))
            .where((item) => item.senderUid != uid && !item.isRead) // Filter out self actions
            .length)
        .handleError((error) {
          debugPrint('❌ Unread count stream error: $error');
        });
  }
}
