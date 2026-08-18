import 'dart:async';
import 'package:get/get.dart';
import '../../../core/services/notification_service.dart';
import '../models/app_notification_model.dart';
import '../../../core/utils/app_logger.dart';

class NotificationController extends GetxController {
  final NotificationService _service = NotificationService();

  final RxList<AppNotificationModel> notifications = <AppNotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString currentUid = ''.obs;
  final RxString currentRole = ''.obs;

  StreamSubscription? _notifSub;
  StreamSubscription? _unreadSub;

  void listenForUser(String uid, {String? role}) {
    if (uid.isEmpty) return;
    if (uid == currentUid.value && role == currentRole.value && _notifSub != null) return;
    currentUid.value = uid;
    currentRole.value = role ?? '';

    _notifSub?.cancel();
    _unreadSub?.cancel();

    _notifSub = _service.getNotificationsStream(uid, role: role).listen((list) {
      notifications.value = list;
    }, onError: (e) {
      AppLogger.e('Error listening to notifications: $e', e, null, 'NOTIF_CTRL');
    });

    _unreadSub = _service.getUnreadCountStream(uid, role: role).listen((count) {
      unreadCount.value = count;
    }, onError: (e) {
      AppLogger.e('Error listening to unread count: $e', e, null, 'NOTIF_CTRL');
    });
  }

  Future<void> markAllRead() async {
    if (currentUid.value.isEmpty) return;
    await _service.markAllAsRead(currentUid.value, role: currentRole.value);
  }

  Future<void> markRead(String id) async {
    await _service.markAsRead(id);
  }

  Future<void> deleteNotification(String id) async {
    await _service.deleteNotification(id);
  }

  Future<void> deleteAllNotifications() async {
    if (currentUid.value.isEmpty) return;
    await _service.deleteAllNotifications(currentUid.value, role: currentRole.value);
  }

  @override
  void onClose() {
    _notifSub?.cancel();
    _unreadSub?.cancel();
    super.onClose();
  }
}
