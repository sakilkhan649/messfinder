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

  Timer? _pollingTimer;

  void listenForUser(String uid, {String? role}) {
    if (uid.isEmpty) return;
    if (uid == currentUid.value && role == currentRole.value && _pollingTimer != null) return;
    currentUid.value = uid;
    currentRole.value = role ?? '';

    _pollingTimer?.cancel();

    // Fetch immediately
    fetchNotifications();

    // Poll every 15 seconds to simulate real-time
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      fetchNotifications();
    });
  }

  Future<void> fetchNotifications() async {
    if (currentUid.value.isEmpty) return;
    try {
      final list = await _service.fetchNotificationsFromApi(currentUid.value);
      notifications.value = list;
      unreadCount.value = list.where((n) => !n.isRead).length;
    } catch (e) {
      AppLogger.e('Error fetching notifications: $e', e, null, 'NOTIF_CTRL');
    }
  }

  Future<void> markAllRead() async {
    // Left unimplemented for backend, but we can optimistically update UI
    for (var n in notifications) {
      if (!n.isRead) {
        n.isRead = true;
        _service.markAsRead(n.id);
      }
    }
    notifications.refresh();
    unreadCount.value = 0;
  }

  Future<void> markRead(String id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !notifications[index].isRead) {
      notifications[index].isRead = true;
      notifications.refresh();
      unreadCount.value = (unreadCount.value - 1).clamp(0, 999);
    }
    await _service.markAsRead(id);
  }

  Future<void> deleteNotification(String id) async {
    notifications.removeWhere((n) => n.id == id);
    // Delete not implemented in backend API yet, skipping actual backend deletion
  }

  Future<void> deleteAllNotifications() async {
    notifications.clear();
    unreadCount.value = 0;
    // Delete all not implemented in backend API yet
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }
}
