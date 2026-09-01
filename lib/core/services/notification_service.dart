import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mess_finder/core/services/api_service.dart';
import 'package:mess_finder/core/utils/api_constants.dart';
import 'package:mess_finder/features/auth/controllers/auth_controller.dart';
import 'package:mess_finder/features/chat/controllers/chat_controller.dart';
import 'package:mess_finder/features/notifications/models/app_notification_model.dart';
import 'package:mess_finder/features/chat/controllers/call_controller.dart';
import 'package:mess_finder/features/marketplace/controllers/marketplace_controller.dart';
/// ─── Background message handler (top-level function, required by FCM) ────────
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📨 [FCM] Background message: ${message.messageId}');
  
  if (message.data['type'] == 'call_ended') {
    final relatedId = message.data['relatedId'];
    if (relatedId != null && relatedId.toString().isNotEmpty) {
      await FlutterCallkitIncoming.endCall(relatedId);
    } else {
      await FlutterCallkitIncoming.endAllCalls();
    }
    return;
  }
  
  if (message.data['type'] == 'call') {
    final callerName = message.data['title'] ?? 'Unknown Caller';
    final body = message.data['body'] ?? '';
    final isVideo = body.toString().toLowerCase().contains('video');
    final senderPhotoUrl = message.data['senderPhotoUrl'];
    final relatedId = message.data['relatedId']; 
    final senderUid = message.data['senderUid'] ?? message.data['sender_uid'];

    // Auto-Busy Check: Prevent ringing if already in an active call (stored via SharedPreferences)
    try {
      final prefs = await SharedPreferences.getInstance();
      final isInCall = prefs.getBool('is_in_call') ?? false;
      if (isInCall) {
        debugPrint('🚫 [FCM Background] User is already in a call, rejecting new call...');
        if (senderUid != null) {
          final url = Uri.parse('${ApiConstants.serverBaseUrl}/api/reject_call');
          await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'callerId': senderUid, 'reason': 'busy'})).timeout(const Duration(seconds: 5));
        }
        return; // Do not show CallKit
      }
    } catch (e) {
      debugPrint('Error checking active call state in background: $e');
    }

    final params = CallKitParams(
      id: relatedId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nameCaller: callerName,
      appName: 'Mess Finder',
      avatar: senderPhotoUrl,
      handle: isVideo ? 'Video Call' : 'Audio Call',
      type: isVideo ? 1 : 0,
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: false,
        subtitle: 'Missed call',
      ),
      duration: 30000,
      extra: <String, dynamic>{
        'relatedId': relatedId, 
        'isVideo': isVideo,
        'senderUid': senderUid,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        actionColor: '#4CAF50',
        textAccept: 'Accept',
        textDecline: 'Decline',
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: '',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );
    
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }
}

/// ─── Core Notification Service ───────────────────────────────────────────────
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
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

    // Fail-safe: Clear any stuck CallKit notifications & reset in-call state on app start
    try {
      await FlutterCallkitIncoming.endAllCalls();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_in_call', false);
    } catch (e) {
      debugPrint('Fail-safe clear error: $e');
    }

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

    // 7. Handle CallKit events
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
      if (event == null) return;
      if (event is CallEventActionCallAccept) {
        final extra = event.callKitParams.extra;
        if (extra != null) {
          final relatedId = extra['relatedId'];
          final isVideo = extra['isVideo'] == true;
          final senderUid = extra['senderUid'];
          
          if (Get.isRegistered<CallController>()) {
            final callCtrl = Get.find<CallController>();
            callCtrl.currentChannel = relatedId;
            callCtrl.isVideoCall.value = isVideo;
            if (senderUid != null) {
              callCtrl.peerUserId = senderUid;
            }
            callCtrl.acceptCall();
          }
        }
      } else if (event is CallEventActionCallDecline) {
        final extra = event.callKitParams.extra;
        if (extra != null) {
          final relatedId = extra['relatedId'];
          final senderUid = extra['senderUid'];

          if (Get.isRegistered<CallController>()) {
            final callCtrl = Get.find<CallController>();
            // Ignore if we are already connecting or connected
            if (callCtrl.currentChannel == relatedId && 
                (callCtrl.callState.value == CallState.connecting || 
                 callCtrl.callState.value == CallState.connected)) {
               debugPrint('Ignoring CallKit Decline event because call is already connected/connecting.');
               return;
            }
          }

          // Fallback HTTP request to reject call instantly even if backgrounded
          if (senderUid != null) {
             try {
                final url = Uri.parse('${ApiConstants.serverBaseUrl}/api/reject_call');
                await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'callerId': senderUid, 'reason': 'declined'})).timeout(const Duration(seconds: 5));
             } catch (e) {
                debugPrint('Failed to reject call via API: $e');
             }
          }

          if (Get.isRegistered<CallController>()) {
            final callCtrl = Get.find<CallController>();
            callCtrl.currentChannel = relatedId;
            if (senderUid != null) {
              callCtrl.peerUserId = senderUid;
            }
            callCtrl.rejectCall();
          }
        }
      }
    });

    debugPrint('✅ [FCM] NotificationService initialized');
  }

  // ── Foreground Message Handler ───────────────────────────────────────────────
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
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
        // FALLBACK: In case WebSocket missed the real-time event, fetch messages silently
        chatCtrl.fetchNewMessagesSilently(chatRoomId);
        return;
      }
    }

    final type = message.data['type'];
    
    if (type == 'call_ended') {
      final relatedId = message.data['relatedId'];
      if (relatedId != null && relatedId.toString().isNotEmpty) {
        FlutterCallkitIncoming.endCall(relatedId);
      } else {
        FlutterCallkitIncoming.endAllCalls();
      }
      return;
    }
    
    if (type == 'new_product') {
      if (Get.isRegistered<MarketplaceController>()) {
        final ctrl = Get.find<MarketplaceController>();
        ctrl.fetchProducts(isRefresh: true);
      }
    }
    
    if (type == 'call') {
      final callerName = message.data['title'] ?? 'Unknown Caller';
      final body = message.data['body'] ?? '';
      final isVideo = body.toString().toLowerCase().contains('video');
      final senderPhotoUrl = message.data['senderPhotoUrl'];
      final relatedId = message.data['relatedId'];
      
      bool isBusy = false;
      
      // Check CallController state
      if (Get.isRegistered<CallController>()) {
        final callCtrl = Get.find<CallController>();
        if (callCtrl.callState.value != CallState.idle) {
          // If the active call is NOT the same as the incoming push, we are busy
          if (callCtrl.currentChannel != relatedId && callCtrl.peerUserId != senderUid) {
            isBusy = true;
          }
        }
      }

      if (isBusy) {
        debugPrint('🚫 [FCM Foreground] User is already in a call, rejecting new call...');
        if (senderUid != null) {
          try {
            final url = Uri.parse('${ApiConstants.serverBaseUrl}/api/reject_call');
            await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'callerId': senderUid, 'reason': 'busy'})).timeout(const Duration(seconds: 5));
          } catch (e) {
            debugPrint('Failed to reject call via API: $e');
          }
        }
        return; // Do not show CallKit
      }

      final params = CallKitParams(
        id: relatedId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        nameCaller: callerName,
        appName: 'Mess Finder',
        avatar: senderPhotoUrl,
        handle: isVideo ? 'Video Call' : 'Audio Call',
        type: isVideo ? 1 : 0,
        duration: 30000,
        extra: <String, dynamic>{
          'relatedId': relatedId, 
          'isVideo': isVideo,
          'senderUid': senderUid,
        },
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0955fa',
          actionColor: '#4CAF50',
          textAccept: 'Accept',
          textDecline: 'Decline',
        ),
        ios: const IOSParams(
          iconName: 'CallKitLogo',
          supportsVideo: true,
          maximumCallGroups: 2,
          maximumCallsPerCallGroup: 1,
          audioSessionActive: true,
          supportsDTMF: true,
          supportsHolding: true,
          ringtonePath: 'system_ringtone_default',
        ),
      );
      
      FlutterCallkitIncoming.showCallkitIncoming(params);
      return;
    }

    if (message.notification != null) {
      showLocalNotification(
        title: message.notification!.title ?? 'MessFinder',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
        imageUrl: message.data['senderPhotoUrl'],
      );
    }
  }

  // ── Show Local Notification (when app is open) ────────────────────────────
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String? imageUrl,
    int id = 0,
  }) async {
    AndroidBitmap<Object>? largeIcon;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          largeIcon = ByteArrayAndroidBitmap(response.bodyBytes);
        }
      } catch (e) {
        debugPrint('Failed to download notification image: $e');
      }
    }

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
          largeIcon: largeIcon,
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
    String? imageUrl,
    String? payload,
  }) async {
    await showLocalNotification(
      id: 9999,
      title: isVideo ? '📹 Incoming Video Call' : '📞 Incoming Audio Call',
      body: '$callerName is calling you...',
      payload: payload,
      imageUrl: imageUrl,
    );
  }

  Future<void> cancelCallNotification() async {
    try {
      await _localNotifications.cancel(9999);
    } catch (e) {
      debugPrint('Cancel notification error: $e');
    }
  }

  Future<void> endCallKitCall(String id) async {
    try {
      await FlutterCallkitIncoming.endCall(id);
    } catch (e) {
      debugPrint('End CallKit call error: $e');
    }
  }

  Future<void> endAllCallKitCalls() async {
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e) {
      debugPrint('End all CallKit calls error: $e');
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

  Future<void> saveTokenToBackend() async {
    try {
      final token = await getToken();
      if (token != null) {
        final apiService = Get.isRegistered<ApiService>() ? Get.find<ApiService>() : ApiService();
        await apiService.dio.put(
          ApiConstants.authUpdateFcmToken,
          data: {'fcmToken': token},
        );
        debugPrint('✅ [FCM] Token saved to backend successfully');
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

  Future<void> clearNotificationsOnLogout() async {
    try {
      await unsubscribeFromTopic('all_users');
      final authCtrl = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
      if (authCtrl?.currentUser.value != null && authCtrl!.currentUser.value!.role.isNotEmpty) {
        await unsubscribeFromTopic(authCtrl.currentUser.value!.role.toLowerCase());
      }
      
      final apiService = Get.isRegistered<ApiService>() ? Get.find<ApiService>() : ApiService();
      await apiService.dio.put(
        ApiConstants.authUpdateFcmToken,
        data: {'fcmToken': ''},
      );
      await _fcm.deleteToken();
      debugPrint('✅ [FCM] Token & topics cleared on logout');
    } catch (e) {
      debugPrint('❌ [FCM] Clear on logout error: $e');
    }
  }

  // ── (Deprecated) Store notification in Firestore ──────────
  Future<void> storeNotification(AppNotificationModel notification) async {
    // We now store directly via the API backend or it stores automatically when sending push
  }

  /// Send push via Vercel Backend (FCM HTTP v1 API)
  Future<void> sendPush({
    required String receiverUid,
    required String title,
    required String body,
    String type = '',
    String relatedId = '',
    String senderUid = '',
    String senderPhotoUrl = '',
  }) async {
    try {
      final vercelUrl = ApiConstants.sendPushNotificationUrl;
      
      final response = await http.post(
        Uri.parse(vercelUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'receiverUid': receiverUid,
          'title': title,
          'body': body,
          'type': type,
          'relatedId': relatedId,
          'senderUid': senderUid,
          'senderPhotoUrl': senderPhotoUrl,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [MainBackend] Push sent successfully');
      } else {
        debugPrint('❌ [MainBackend] Push failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [MainBackend] sendPush error: $e');
    }
  }

  /// Helper: Send push to a topic
  Future<void> sendPushToTopic({
    required String topic,
    required String title,
    required String body,
    String senderUid = '',
    String senderPhotoUrl = '',
    Map<String, String> data = const {},
  }) async {
    await sendPush(
      receiverUid: '/topics/$topic',
      title: title,
      body: body,
      type: data['type'] ?? '',
      relatedId: data['relatedId'] ?? '',
      senderUid: senderUid.isNotEmpty ? senderUid : (data['senderUid'] ?? ''),
      senderPhotoUrl: senderPhotoUrl,
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

    // Storage happens automatically on the backend via internalSendPushNotification

    // 2. Send push notification via API
    await sendPush(
      receiverUid: receiverUid,
      title: title,
      body: body,
      type: type.name,
      relatedId: relatedId ?? '',
      senderUid: senderUid ?? '',
      senderPhotoUrl: extraData['senderPhotoUrl'] ?? '',
    );
  }

  // ── Mark notification as read via API ────────────────────────────────────────────
  Future<void> markAsRead(String notificationId) async {
    try {
      final apiService = Get.isRegistered<ApiService>() ? Get.find<ApiService>() : ApiService();
      await apiService.dio.put('/notifications/$notificationId/read');
    } catch (e) {
      debugPrint('❌ [API] markAsRead error: $e');
    }
  }

  // ── Delete notification via API ────────────────────────────────────────────
  Future<void> deleteNotification(String notificationId) async {
    try {
      final apiService = Get.isRegistered<ApiService>() ? Get.find<ApiService>() : ApiService();
      await apiService.dio.delete('/notifications/$notificationId');
    } catch (e) {
      debugPrint('❌ [API] deleteNotification error: $e');
    }
  }

  // ── Delete all notifications via API ────────────────────────────────────────────
  Future<void> deleteAllNotifications(String uid) async {
    try {
      final apiService = Get.isRegistered<ApiService>() ? Get.find<ApiService>() : ApiService();
      await apiService.dio.delete('/notifications/all/$uid');
    } catch (e) {
      debugPrint('❌ [API] deleteAllNotifications error: $e');
    }
  }

  Future<List<AppNotificationModel>> fetchNotificationsFromApi(String uid) async {
    try {
      final apiService = Get.isRegistered<ApiService>() ? Get.find<ApiService>() : ApiService();
      final response = await apiService.dio.get(
        '/notifications/$uid',
        queryParameters: {'t': DateTime.now().millisecondsSinceEpoch},
      );
      
      final data = response.data as List<dynamic>;
      final list = data.map((item) => AppNotificationModel.fromMap(item, item['id'])).toList();
      
      // Filter out self actions (though backend shouldn't send them)
      final filteredList = list.where((item) => item.senderUid != uid).toList();
      filteredList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filteredList;
    } catch (e) {
      debugPrint('❌ [API] fetchNotificationsFromApi error: $e');
      return [];
    }
  }
}
