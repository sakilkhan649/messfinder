import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../core/network/api_checker.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/models/user_model.dart';
import '../../bachelor/models/booking_model.dart';
import '../../landlord/models/post_model.dart';
import '../../notifications/models/app_notification_model.dart';
import '../../payment/models/payment_model.dart';
import '../models/admin_stats_model.dart';
import '../repositories/admin_repo.dart';

/// ===================================================================
/// [CONTROLLER LAYER - MVC PATTERN]
/// Handles all business logic, caching, and state management for Admin.
/// ===================================================================
class AdminController extends GetxController {
  final AdminRepository _adminRepo = AdminRepository();

  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;

  final RxInt selectedCategoryIndex = 0.obs; // 0: Bookings, 1: Posts
  final RxInt selectedTabIndex = 0.obs;      // 0: Pending, 1: Approved, 2: Rejected
  final RxString searchQuery = ''.obs;
  final RxInt currentNavIndex = 0.obs;       // 0: Overview, 1: Requests, 2: Users, 3: Profile
  final RxInt selectedUserRoleIndex = 0.obs; // 0: Landlord, 1: Bachelor

  // Reactive Data Stores
  final RxList<UserModel> allUsers = <UserModel>[].obs;
  final RxList<PostModel> allPosts = <PostModel>[].obs;
  final RxList<BookingModel> allBookings = <BookingModel>[].obs;
  final RxList<PaymentModel> allPayments = <PaymentModel>[].obs;
  final Rx<AdminStatsModel> adminStats = AdminStatsModel.empty().obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  void changeNavIndex(int index) {
    currentNavIndex.value = index;
  }

  void setCategory(int index) {
    if (selectedCategoryIndex.value != index) {
      selectedCategoryIndex.value = index;
      selectedTabIndex.value = 0; // Reset to Pending tab on category change
    }
  }

  void setTab(int index) {
    selectedTabIndex.value = index;
  }

  void setUserRoleTab(int index) {
    selectedUserRoleIndex.value = index;
  }

  void updateSearch(String query) {
    searchQuery.value = query;
  }

  // ─── Fetch All Data from Backend REST API ─────────────────────────────────
  Future<void> fetchDashboardData({bool showLoader = true}) async {
    if (showLoader) isLoading.value = true;
    try {
      AppLogger.i('Fetching admin dashboard data from API...', tag: 'ADMIN_CONTROLLER');

      final results = await Future.wait([
        _adminRepo.getAdminStats(),
        _adminRepo.getAllUsers(),
        _adminRepo.getAllPosts(),
        _adminRepo.getAllBookings(),
        _adminRepo.getAllPayments(),
      ]);

      adminStats.value = results[0] as AdminStatsModel;
      allUsers.assignAll(results[1] as List<UserModel>);
      allPosts.assignAll(results[2] as List<PostModel>);
      allBookings.assignAll(results[3] as List<BookingModel>);
      allPayments.assignAll(results[4] as List<PaymentModel>);

      AppLogger.s(
        'Admin data loaded successfully: ${allUsers.length} users, ${allPosts.length} posts, ${allBookings.length} bookings',
        tag: 'ADMIN_CONTROLLER',
      );
    } catch (e, stack) {
      AppLogger.e('Failed to load admin data: $e', e, stack, 'ADMIN_CONTROLLER');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  // ─── Streams for reactive view consumption ────────────────────────────────
  Stream<List<UserModel>> get allUsersStream => allUsers.stream;
  Stream<List<PostModel>> get allPostsStream => allPosts.stream;
  Stream<List<BookingModel>> get allBookingsStream => allBookings.stream;
  Stream<List<PaymentModel>> get allPaymentsStream => allPayments.stream;

  Stream<List<PostModel>> get pendingPostsStream =>
      allPosts.stream.map((posts) => posts.where((p) => p.paymentStatus.trim().toLowerCase() == 'pending').toList());

  Stream<List<BookingModel>> get pendingBookingsStream =>
      allBookings.stream.map((bookings) => bookings.where((b) => b.paymentStatus.trim().toLowerCase() == 'pending').toList());

  AdminStatsModel calculateStats({
    required List<BookingModel> bookings,
    required List<PostModel> posts,
  }) {
    return AdminStatsModel.fromData(bookings: bookings, posts: posts);
  }

  // ─── User Helper Methods ──────────────────────────────────────────────────
  bool isAdminUser(UserModel u) {
    return u.role.trim().toLowerCase() == 'admin';
  }

  bool isLandlordUser(UserModel u, List<PostModel> posts, List<PaymentModel> payments) {
    if (isAdminUser(u)) return false;
    if (u.role.trim().toLowerCase() == 'landlord') return true;
    if (posts.any((p) => p.ownerUid == u.uid)) return true;
    return false;
  }

  bool isBachelorUser(
    UserModel u,
    List<BookingModel> bookings,
    List<PaymentModel> payments,
    List<PostModel> posts,
  ) {
    if (isAdminUser(u)) return false;
    if (isLandlordUser(u, posts, payments)) return false;
    return true;
  }

  Map<String, String> getUserContactInfo(
    UserModel user,
    List<PostModel> allPostsList,
    List<BookingModel> allBookingsList,
    List<PaymentModel> allPaymentsList,
  ) {
    String phone = user.phone.trim();
    String trxId = user.trxId?.trim() ?? '';

    for (final p in allPaymentsList) {
      if (p.userUid == user.uid ||
          (p.userPhone.isNotEmpty && p.userPhone == phone)) {
        if (phone.isEmpty && p.userPhone.isNotEmpty) {
          phone = p.userPhone;
        }
        if (trxId.isEmpty && p.trxId.isNotEmpty) {
          trxId = p.trxId;
        }
      }
    }

    for (final post in allPostsList) {
      if (post.ownerUid == user.uid ||
          (post.ownerPhone != null &&
              post.ownerPhone!.isNotEmpty &&
              post.ownerPhone == phone)) {
        if (phone.isEmpty &&
            post.ownerPhone != null &&
            post.ownerPhone!.isNotEmpty) {
          phone = post.ownerPhone!;
        }
        if (trxId.isEmpty &&
            post.paymentTrxId != null &&
            post.paymentTrxId!.isNotEmpty) {
          trxId = post.paymentTrxId!;
        }
      }
    }

    for (final booking in allBookingsList) {
      if (booking.bachelorUid == user.uid ||
          (booking.bachelorPhone != null &&
              booking.bachelorPhone!.isNotEmpty &&
              booking.bachelorPhone == phone)) {
        if (phone.isEmpty &&
            booking.bachelorPhone != null &&
            booking.bachelorPhone!.isNotEmpty) {
          phone = booking.bachelorPhone!;
        }
        if (trxId.isEmpty && booking.trxId.isNotEmpty) {
          trxId = booking.trxId;
        }
      }
    }

    return {
      'phone': phone.isNotEmpty ? phone : 'No phone number',
      'trxId': trxId.isNotEmpty ? trxId : 'Not submitted',
    };
  }

  // ─── User Actions ─────────────────────────────────────────────────────────
  Future<void> deleteUserByUid(String uid, String name) async {
    isLoading.value = true;
    AppLogger.w('Deleting user via API: $name ($uid)', tag: 'ADMIN_CONTROLLER');
    try {
      await _adminRepo.deleteUser(uid);
      allUsers.removeWhere((u) => u.uid == uid);
      AppLogger.s('User deleted successfully: $uid', tag: 'ADMIN_CONTROLLER');
      ApiChecker.showSuccess(
        'User "$name" has been deleted.',
        title: 'Deleted Successfully',
      );
      fetchDashboardData(showLoader: false);
    } catch (e, stack) {
      AppLogger.e('Failed to delete user: $e', e, stack, 'ADMIN_CONTROLLER');
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  void confirmDeleteUser(UserModel user) {
    Get.defaultDialog(
      title: 'Delete User',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      middleText:
          'Are you sure you want to delete "${user.name}"?\nThis will permanently remove their account and all associated data.',
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFFE53935),
      onConfirm: () {
        Get.back();
        deleteUserByUid(user.uid, user.name);
      },
    );
  }

  // ─── Post Actions ─────────────────────────────────────────────────────────
  Future<void> approvePost(PostModel post) async {
    isLoading.value = true;
    AppLogger.i('Approving post via API: ${post.title} (${post.postId})', tag: 'ADMIN_CONTROLLER');
    try {
      await _adminRepo.approvePost(post.postId);
      
      // Notify post owner (Landlord)
      if (post.ownerUid.isNotEmpty) {
        NotificationService().sendAndStore(
          receiverUid: post.ownerUid,
          title: 'Post Approved! 🎉',
          body: 'Your mess listing "${post.title}" has been verified and published!',
          type: NotificationType.general,
          relatedId: post.postId,
        );
      }

      AppLogger.s('Post approved successfully: ${post.postId}', tag: 'ADMIN_CONTROLLER');
      ApiChecker.showSuccess(
        '"${post.title}" has been approved and published!',
        title: 'Post Approved',
      );
      fetchDashboardData(showLoader: false);
    } catch (e, stack) {
      AppLogger.e('Failed to approve post: $e', e, stack, 'ADMIN_CONTROLLER');
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectPost(PostModel post) async {
    isLoading.value = true;
    AppLogger.w('Rejecting post via API: ${post.title} (${post.postId})', tag: 'ADMIN_CONTROLLER');
    try {
      await _adminRepo.rejectPost(post.postId);
      
      // Notify post owner (Landlord)
      if (post.ownerUid.isNotEmpty) {
        NotificationService().sendAndStore(
          receiverUid: post.ownerUid,
          title: 'Post Rejected ❌',
          body: 'Your mess listing "${post.title}" was not approved or payment could not be verified.',
          type: NotificationType.general,
          relatedId: post.postId,
        );
      }

      AppLogger.s('Post rejected successfully: ${post.postId}', tag: 'ADMIN_CONTROLLER');
      ApiChecker.showSuccess(
        '"${post.title}" has been rejected!',
        title: 'Post Rejected',
      );
      fetchDashboardData(showLoader: false);
    } catch (e, stack) {
      AppLogger.e('Failed to reject post: $e', e, stack, 'ADMIN_CONTROLLER');
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deletePost(PostModel post) async {
    isLoading.value = true;
    AppLogger.w('Deleting post via API: ${post.title} (${post.postId})', tag: 'ADMIN_CONTROLLER');
    try {
      await _adminRepo.deletePost(post.postId);
      allPosts.removeWhere((p) => p.postId == post.postId);
      AppLogger.s('Post deleted successfully: ${post.postId}', tag: 'ADMIN_CONTROLLER');
      ApiChecker.showSuccess(
        'Post "${post.title}" has been permanently deleted.',
        title: 'Deleted Successfully',
      );
      fetchDashboardData(showLoader: false);
    } catch (e, stack) {
      AppLogger.e('Failed to delete post: $e', e, stack, 'ADMIN_CONTROLLER');
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  void confirmDeletePost(PostModel post) {
    Get.defaultDialog(
      title: 'Delete Post',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      middleText:
          'Are you sure you want to permanently delete "${post.title}"?\nThis action cannot be undone.',
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFFE53935),
      onConfirm: () {
        Get.back();
        deletePost(post);
      },
    );
  }

  // ─── Booking Actions ──────────────────────────────────────────────────────
  Future<void> approveBooking(BookingModel booking) async {
    isLoading.value = true;
    AppLogger.i('Approving booking via API: ${booking.bookingId}', tag: 'ADMIN_CONTROLLER');
    try {
      await _adminRepo.approveBooking(booking.bookingId);
      
      // Send real-time in-app notification & push to Bachelor
      if (booking.bachelorUid.isNotEmpty) {
        NotificationService().sendAndStore(
          receiverUid: booking.bachelorUid,
          title: 'Booking Approved! 🎉',
          body: 'Your payment was verified. You can now contact the landlord directly.',
          type: NotificationType.bookingApproved,
          relatedId: booking.postId,
        );
      }

      // Send real-time in-app notification & push to Landlord
      if (booking.landlordUid.isNotEmpty) {
        NotificationService().sendAndStore(
          receiverUid: booking.landlordUid,
          title: 'Booking Payment Verified 💰',
          body: '${booking.bachelorName ?? "A bachelor"} has paid the booking fee. They might contact you soon.',
          type: NotificationType.paymentVerified,
          relatedId: booking.postId,
        );
      }

      AppLogger.s('Booking approved successfully: ${booking.bookingId}', tag: 'ADMIN_CONTROLLER');
      ApiChecker.showSuccess(
        'Booking approved successfully! The mess listing has been updated.',
        title: 'Booking Approved',
      );
      fetchDashboardData(showLoader: false);
    } catch (e, stack) {
      AppLogger.e('Failed to approve booking: $e', e, stack, 'ADMIN_CONTROLLER');
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectBooking(BookingModel booking) async {
    isLoading.value = true;
    AppLogger.w('Rejecting booking via API: ${booking.bookingId}', tag: 'ADMIN_CONTROLLER');
    try {
      await _adminRepo.rejectBooking(booking.bookingId);
      
      // Notify Bachelor
      if (booking.bachelorUid.isNotEmpty) {
        NotificationService().sendAndStore(
          receiverUid: booking.bachelorUid,
          title: 'Booking Rejected ❌',
          body: 'Your booking request was rejected or payment could not be verified.',
          type: NotificationType.bookingRejected,
          relatedId: booking.postId,
        );
      }

      AppLogger.s('Booking rejected successfully: ${booking.bookingId}', tag: 'ADMIN_CONTROLLER');
      ApiChecker.showSuccess(
        'Booking request has been rejected!',
        title: 'Booking Rejected',
      );
      fetchDashboardData(showLoader: false);
    } catch (e, stack) {
      AppLogger.e('Failed to reject booking: $e', e, stack, 'ADMIN_CONTROLLER');
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteBooking(BookingModel booking) async {
    isLoading.value = true;
    AppLogger.w('Deleting booking via API: ${booking.bookingId}', tag: 'ADMIN_CONTROLLER');
    try {
      await _adminRepo.deleteBooking(booking.bookingId);
      allBookings.removeWhere((b) => b.bookingId == booking.bookingId);
      AppLogger.s('Booking deleted successfully: ${booking.bookingId}', tag: 'ADMIN_CONTROLLER');
      ApiChecker.showSuccess(
        'Booking record has been permanently deleted.',
        title: 'Deleted Successfully',
      );
      fetchDashboardData(showLoader: false);
    } catch (e, stack) {
      AppLogger.e('Failed to delete booking: $e', e, stack, 'ADMIN_CONTROLLER');
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  void confirmDeleteBooking(BookingModel booking) {
    Get.defaultDialog(
      title: 'Delete Booking',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      middleText:
          'Are you sure you want to permanently delete this booking record?\nThis action cannot be undone.',
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFFE53935),
      onConfirm: () {
        Get.back();
        deleteBooking(booking);
      },
    );
  }

  // ─── Broadcast Notification ───────────────────────────────────────────────
  Future<bool> sendBroadcastAnnouncement({
    required String title,
    required String body,
    String targetRole = 'all',
  }) async {
    isLoading.value = true;
    try {
      // 1. Send via Backend API
      try {
        await _adminRepo.broadcastNotification(
          title: title,
          body: body,
          targetRole: targetRole,
        );
      } catch (e) {
        AppLogger.w('Backend API broadcast note: $e', tag: 'ADMIN_CONTROLLER');
      }

      // 2. Store in Firestore notification center for real-time app delivery
      final notifService = NotificationService();
      final target = targetRole.toLowerCase().trim();
      await notifService.storeNotification(
        AppNotificationModel(
          id: '',
          title: title,
          body: body,
          type: NotificationType.adminBroadcast,
          receiverUid: target, // 'all', 'landlord', or 'bachelor'
          createdAt: DateTime.now(),
        ),
      );

      // 3. Send Push notification via FCM Topic
      if (target == 'all') {
        await notifService.sendPushToTopic(
          topic: 'all_users',
          title: title,
          body: body,
          data: {'type': 'adminBroadcast'},
        );
      } else {
        await notifService.sendPushToTopic(
          topic: target,
          title: title,
          body: body,
          data: {'type': 'adminBroadcast'},
        );
      }

      ApiChecker.showSuccess(
        'Announcement broadcasted to users successfully!',
        title: 'Broadcast Sent',
      );
      return true;
    } catch (e, stack) {
      AppLogger.e('Error broadcasting announcement: $e', e, stack, 'ADMIN_CONTROLLER');
      ApiChecker.checkApi(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
