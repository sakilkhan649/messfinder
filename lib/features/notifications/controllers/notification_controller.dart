import 'dart:async';
import 'package:get/get.dart';
import '../../../core/services/notification_service.dart';
import '../models/app_notification_model.dart';

class NotificationController extends GetxController {
  final NotificationService _service = NotificationService();

  final RxList<AppNotificationModel> notifications = <AppNotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString currentUid = ''.obs;

  StreamSubscription? _notifSub;
  StreamSubscription? _unreadSub;

  void listenForUser(String uid) {
    if (uid.isEmpty || uid == currentUid.value) return;
    currentUid.value = uid;

    _notifSub?.cancel();
    _unreadSub?.cancel();

    _notifSub = _service.getNotificationsStream(uid).listen((list) {
      notifications.value = list;
    });

    _unreadSub = _service.getUnreadCountStream(uid).listen((count) {
      unreadCount.value = count;
    });
  }

  Future<void> markAllRead() async {
    if (currentUid.value.isEmpty) return;
    await _service.markAllAsRead(currentUid.value);
  }

  Future<void> markRead(String id) async {
    await _service.markAsRead(id);
  }

  @override
  void onClose() {
    _notifSub?.cancel();
    _unreadSub?.cancel();
    super.onClose();
  }
}
