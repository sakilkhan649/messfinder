import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/network/api_checker.dart';
import '../../../core/utils/api_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/models/user_model.dart';
import '../../bachelor/models/booking_model.dart';
import '../../bachelor/repositories/booking_repo.dart';
import '../../landlord/models/post_model.dart';
import '../../landlord/repositories/post_repo.dart';
import '../../payment/models/payment_model.dart';
import '../models/admin_stats_model.dart';

/// ===================================================================
/// [CONTROLLER LAYER - MVC PATTERN]
/// AdminController: অ্যাডমিন মডিউলের যাবতীয় বিজনেস লজিক, ফায়ারবেস ডেটা
/// স্ট্রীম এবং রিঅ্যাক্টিভ স্টেট (Reactive State) পরিচালনা করে।
/// 
/// View থেকে যেকোনো অ্যাকশন (Approve, Reject, Delete, Tab change)
/// এই কন্ট্রোলারের মাধ্যমে প্রক্রিয়াজাত হয়।
/// ===================================================================
class AdminController extends GetxController {
  final PostRepository _postRepo = PostRepository();
  final BookingRepository _bookingRepo = BookingRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── রিঅ্যাক্টিভ স্টেট (Reactive State Variables) ───
  final RxBool isLoading = false.obs;
  final RxInt selectedCategoryIndex = 0.obs; // 0: Bookings, 1: Posts
  final RxInt selectedTabIndex = 0.obs;      // 0: Pending, 1: Approved, 2: Rejected
  final RxString searchQuery = ''.obs;
  final RxInt currentNavIndex = 0.obs;       // 0: Overview, 1: Requests, 2: Users
  final RxInt selectedUserRoleIndex = 0.obs; // 0: Landlord, 1: Bachelor

  // ─── নেভিগেশন ও ট্যাব পরিবর্তন লজিক ───
  void changeNavIndex(int index) {
    currentNavIndex.value = index;
  }

  void setCategory(int index) {
    if (selectedCategoryIndex.value != index) {
      selectedCategoryIndex.value = index;
      selectedTabIndex.value = 0; // ক্যাটাগরি বদলালে ডিফল্টভাবে Pending ট্যাবে যাবে
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

  // ─── ডেটা স্ট্রীম (Firestore Real-time Streams) ───

  /// সব রেজিস্টার্ড ইউজারের স্ট্রীম (Users Tab-এর জন্য)
  Stream<List<UserModel>> get allUsersStream {
    return _firestore
        .collection(ApiConstants.usersCollection)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// মেস লিস্টিং পোস্টের স্ট্রীমসমূহ
  Stream<List<PostModel>> get pendingPostsStream =>
      _postRepo.getPendingPostsStream();

  Stream<List<PostModel>> get allPostsStream =>
      _postRepo.getAdminAllPostsStream();

  /// ব্যাচেলর বুকিং রিকোয়েস্টের স্ট্রীমসমূহ
  Stream<List<BookingModel>> get pendingBookingsStream =>
      _bookingRepo.getPendingBookingsStream();

  Stream<List<BookingModel>> get allBookingsStream =>
      _bookingRepo.getAllBookingsStream();

  /// সব পেমেন্ট রিকোয়েস্টের স্ট্রীম (উভয় রোলের অ্যাকাউন্টের তথ্য পাওয়ার জন্য)
  Stream<List<PaymentModel>> get allPaymentsStream {
    return _firestore
        .collection(ApiConstants.paymentsCollection)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // ─── পরিসংখ্যান হিসাব (Stats Computation for Overview Tab) ───
  AdminStatsModel calculateStats({
    required List<BookingModel> bookings,
    required List<PostModel> posts,
  }) {
    return AdminStatsModel.fromData(bookings: bookings, posts: posts);
  }

  /// ইউজার বাড়িওয়ালা ট্যাবে দেখানোর যোগ্য কিনা তা যাচাই
  bool isLandlordUser(UserModel u, List<PostModel> posts, List<PaymentModel> payments) {
    if (u.role.trim().toLowerCase() == 'landlord') return true;
    if (posts.any((p) => p.ownerUid == u.uid)) return true;
    if (payments.any((p) =>
        p.userUid == u.uid && p.role.trim().toLowerCase() == 'landlord')) {
      return true;
    }
    return false;
  }

  /// ইউজার ব্যাচেলর ট্যাবে দেখানোর যোগ্য কিনা তা যাচাই
  /// (একই ইউজার ২টি রোলেই অ্যাকাউন্ট খুললে ২ ট্যাবেই দেখাবে)
  bool isBachelorUser(
    UserModel u,
    List<BookingModel> bookings,
    List<PaymentModel> payments,
    List<PostModel> posts,
  ) {
    if (u.role.trim().toLowerCase() == 'bachelor') return true;
    if (bookings.any((b) => b.bachelorUid == u.uid)) return true;
    if (payments.any((p) =>
        p.userUid == u.uid && p.role.trim().toLowerCase() == 'bachelor')) {
      return true;
    }
    // যদি বাড়িওয়ালা হিসেবে কোনো পোস্ট বা ল্যান্ডলর্ড পেমেন্ট না থাকে, তবুও ব্যাচেলর হিসেবে দেখাবে
    if (!isLandlordUser(u, posts, payments)) return true;
    return false;
  }

  /// ইউজার কার্ডের জন্য সঠিক ফোন নম্বর এবং TrxID বের করার মেথড
  /// (UserModel, PostModel, BookingModel, PaymentModel থেকে মিলিয়ে ডেটা বের করা হয়)
  Map<String, String> getUserContactInfo(
    UserModel user,
    List<PostModel> allPosts,
    List<BookingModel> allBookings,
    List<PaymentModel> allPayments,
  ) {
    String phone = user.phone.trim();
    String trxId = user.trxId?.trim() ?? '';

    // ১. পেমেন্ট রেকর্ড থেকে আগে খুঁজি
    for (final p in allPayments) {
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

    // ২. যদি ইউজার বাড়িওয়ালা হয়, মেস পোস্ট থেকেও খুঁজি
    if (user.isLandlord || user.role.trim().toLowerCase() == 'landlord') {
      for (final post in allPosts) {
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
    }

    // ৩. ব্যাচেলর হলে বুকিং থেকেও খুঁজি
    for (final booking in allBookings) {
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

  // ─── ইউজার ডিলিট লজিক (User Deletion Logic) ───
  Future<void> deleteUserByUid(String uid, String name) async {
    isLoading.value = true;
    AppLogger.w('Deleting user: $name ($uid)', tag: 'ADMIN_CONTROLLER');
    try {
      await _firestore.collection(ApiConstants.usersCollection).doc(uid).delete();
      AppLogger.s('User deleted successfully: $uid', tag: 'ADMIN_CONTROLLER');
      ApiChecker.showSuccess(
        'User "$name" has been deleted.',
        title: 'Deleted Successfully',
      );
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
          'Are you sure you want to delete "${user.name}"?\nThis will permanently remove their account from Firestore.',
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

  // ─── মেস পোস্ট অনুমোদন ও বাতিল লজিক (Post Approval/Rejection) ───
  Future<void> approvePost(PostModel post) async {
    isLoading.value = true;
    AppLogger.i('পোস্ট অ্যাপ্রুভ করা হচ্ছে: ${post.title} (${post.postId})',
        tag: 'ADMIN_CONTROLLER');
    try {
      await _postRepo.approvePost(post.postId);
      AppLogger.s('পোস্ট অ্যাপ্রুভ সফল: ${post.postId}',
          tag: 'ADMIN_CONTROLLER');
      ApiChecker.showSuccess(
        '"${post.title}" has been approved and published!',
        title: 'Post Approved',
      );
    } catch (e, stack) {
      AppLogger.e('পোস্ট অ্যাপ্রুভ ব্যর্থ: $e', e, stack, 'ADMIN_CONTROLLER');
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectPost(PostModel post) async {
    isLoading.value = true;
    AppLogger.w('পোস্ট রিজেক্ট করা হচ্ছে: ${post.title} (${post.postId})',
        tag: 'ADMIN_CONTROLLER');
    try {
      await _postRepo.rejectPost(post.postId);
      AppLogger.s('পোস্ট রিজেক্ট সম্পন্ন: ${post.postId}',
          tag: 'ADMIN_CONTROLLER');
      ApiChecker.showSuccess(
        '"${post.title}" has been rejected!',
        title: 'Post Rejected',
      );
    } catch (e, stack) {
      AppLogger.e('পোস্ট রিজেক্ট ব্যর্থ: $e', e, stack, 'ADMIN_CONTROLLER');
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── ব্যাচেলর বুকিং অনুমোদন ও বাতিল লজিক (Booking Approval/Rejection) ───
  Future<void> approveBooking(BookingModel booking) async {
    isLoading.value = true;
    AppLogger.i(
        'বুকিং অ্যাপ্রুভ ও আনলক করা হচ্ছে: ${booking.bookingId}',
        tag: 'ADMIN_CONTROLLER');
    try {
      await _bookingRepo.approveBooking(booking.bookingId);
      // বাড়িওয়ালা যদি বন্ধ করতে ভুলে যান, তাই বুকিং কনফার্ম হওয়ার সাথে সাথে স্বয়ংক্রিয়ভাবে মেস পোস্টটি বন্ধ (বুকড) করা হচ্ছে
      try {
        await _postRepo.togglePostAvailability(booking.postId, false);
        AppLogger.s(
            'স্বয়ংক্রিয়ভাবে মেস পোস্ট বন্ধ (বুকড) করা হয়েছে: ${booking.postId}',
            tag: 'ADMIN_CONTROLLER');
      } catch (e) {
        AppLogger.w('পোস্ট স্ট্যাটাস বন্ধ করতে সমস্যা: $e',
            tag: 'ADMIN_CONTROLLER');
      }
      AppLogger.s('বুকিং অ্যাপ্রুভ সফল: ${booking.bookingId}',
          tag: 'ADMIN_CONTROLLER');
      ApiChecker.showSuccess(
        'Booking approved successfully! The mess listing has been automatically marked as Booked.',
        title: 'Booking Approved & Closed',
      );
    } catch (e, stack) {
      AppLogger.e('বুকিং অ্যাপ্রুভ ব্যর্থ: $e', e, stack, 'ADMIN_CONTROLLER');
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectBooking(BookingModel booking) async {
    isLoading.value = true;
    AppLogger.w('বুকিং রিজেক্ট করা হচ্ছে: ${booking.bookingId}',
        tag: 'ADMIN_CONTROLLER');
    try {
      await _bookingRepo.rejectBooking(booking.bookingId);
      AppLogger.s('বুকিং রিজেক্ট সম্পন্ন: ${booking.bookingId}',
          tag: 'ADMIN_CONTROLLER');
      ApiChecker.showSuccess(
        'Booking request has been rejected!',
        title: 'Booking Rejected',
      );
    } catch (e, stack) {
      AppLogger.e('বুকিং রিজেক্ট ব্যর্থ: $e', e, stack, 'ADMIN_CONTROLLER');
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── পোস্ট এবং বুকিং স্থায়ীভাবে ডিলিট (Swipe to Delete for Approved/Rejected) ───
  Future<void> deletePost(PostModel post) async {
    isLoading.value = true;
    AppLogger.w('Deleting post: ${post.title} (${post.postId})',
        tag: 'ADMIN_CONTROLLER');
    try {
      await _firestore
          .collection(ApiConstants.postsCollection)
          .doc(post.postId)
          .delete();
      AppLogger.s('Post deleted successfully: ${post.postId}',
          tag: 'ADMIN_CONTROLLER');
      ApiChecker.showSuccess(
        'Post "${post.title}" has been permanently deleted.',
        title: 'Deleted Successfully',
      );
    } catch (e, stack) {
      AppLogger.e('Failed to delete post: $e', e, stack, 'ADMIN_CONTROLLER');
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  void confirmDeletePost(PostModel post) {
    Get.defaultDialog(
      title: 'Delete Approved Post',
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

  Future<void> deleteBooking(BookingModel booking) async {
    isLoading.value = true;
    AppLogger.w('Deleting booking: ${booking.bookingId}',
        tag: 'ADMIN_CONTROLLER');
    try {
      await _firestore
          .collection(ApiConstants.bookingsCollection)
          .doc(booking.bookingId)
          .delete();
      AppLogger.s('Booking deleted successfully: ${booking.bookingId}',
          tag: 'ADMIN_CONTROLLER');
      ApiChecker.showSuccess(
        'Booking record has been permanently deleted.',
        title: 'Deleted Successfully',
      );
    } catch (e, stack) {
      AppLogger.e('Failed to delete booking: $e', e, stack, 'ADMIN_CONTROLLER');
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  void confirmDeleteBooking(BookingModel booking) {
    Get.defaultDialog(
      title: 'Delete Approved Booking',
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
}
