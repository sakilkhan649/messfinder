import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/utils/api_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../bachelor/models/booking_model.dart';
import '../../bachelor/repositories/booking_repo.dart';
import '../models/post_model.dart';

class TenantLeadsController extends GetxController {
  final BookingRepository _bookingRepo = BookingRepository();
  final AuthController _authController = Get.find<AuthController>();

  final RxInt selectedTabIndex = 0.obs; // 0 = Pending, 1 = Approved, 2 = Rejected
  final RxString searchQuery = ''.obs;

  // Cache user data (uid -> {name, phone}) to prevent redundant Firestore queries
  final RxMap<String, Map<String, String>> userCache =
      <String, Map<String, String>>{}.obs;

  void setTab(int index) {
    selectedTabIndex.value = index;
  }

  void updateSearch(String query) {
    searchQuery.value = query;
  }

  Stream<List<BookingModel>> getLeadsStream(PostModel? post) {
    if (post != null) {
      return _bookingRepo.getLeadsForPost(post.postId);
    }
    final landlordUid = _authController.currentUser.value?.uid ?? '';
    return _bookingRepo.getLeadsForLandlord(landlordUid);
  }

  static String _formatEmailToName(String? email) {
    if (email == null || !email.contains('@')) return '';
    final prefix = email.split('@').first;
    final cleaned = prefix.replaceAll(RegExp(r'[^a-zA-Z]'), ' ').trim();
    if (cleaned.isEmpty) return '';
    return cleaned
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  Future<String?> _resolveRealName(
    String uid,
    BookingModel booking,
    Map<String, dynamic>? data,
  ) async {
    // 1. From booking.bachelorName
    if (booking.bachelorName != null &&
        booking.bachelorName!.trim().isNotEmpty &&
        booking.bachelorName!.trim().toLowerCase() != 'user') {
      return booking.bachelorName!.trim();
    }
    // 2. From AuthController if currently logged in user is this bachelor
    if (Get.isRegistered<AuthController>()) {
      final curr = Get.find<AuthController>().currentUser.value;
      if (curr != null &&
          curr.uid == uid &&
          curr.name.trim().isNotEmpty &&
          curr.name.trim().toLowerCase() != 'user') {
        return curr.name.trim();
      }
    }
    // 3. From payments collection by userUid
    try {
      final payQuery = await FirebaseFirestore.instance
          .collection(ApiConstants.paymentsCollection)
          .where('userUid', isEqualTo: uid)
          .limit(1)
          .get();
      if (payQuery.docs.isNotEmpty) {
        final pName =
            payQuery.docs.first.data()['userName']?.toString().trim() ?? '';
        if (pName.isNotEmpty && pName.toLowerCase() != 'user') {
          return pName;
        }
      }
    } catch (_) {}
    // 4. From payments collection by senderNumber (matches payment record by phone number)
    if (booking.senderNumber.isNotEmpty) {
      try {
        final payPhoneQuery = await FirebaseFirestore.instance
            .collection(ApiConstants.paymentsCollection)
            .where('senderNumber', isEqualTo: booking.senderNumber)
            .limit(1)
            .get();
        if (payPhoneQuery.docs.isNotEmpty) {
          final pName = payPhoneQuery.docs.first
                  .data()['userName']
                  ?.toString()
                  .trim() ??
              '';
          if (pName.isNotEmpty && pName.toLowerCase() != 'user') {
            return pName;
          }
        }
      } catch (_) {}
    }
    // 5. From users collection by phone number (in case uid changed or another doc has real name)
    if (booking.senderNumber.isNotEmpty) {
      try {
        final userPhoneQuery = await FirebaseFirestore.instance
            .collection(ApiConstants.usersCollection)
            .where('phone', isEqualTo: booking.senderNumber)
            .limit(5)
            .get();
        for (final doc in userPhoneQuery.docs) {
          final uName = doc.data()['name']?.toString().trim() ?? '';
          if (uName.isNotEmpty && uName.toLowerCase() != 'user') {
            return uName;
          }
        }
      } catch (_) {}
    }
    // 6. From posts collection (if they ever posted a room as landlord/roommate)
    try {
      final postQuery = await FirebaseFirestore.instance
          .collection(ApiConstants.postsCollection)
          .where('ownerUid', isEqualTo: uid)
          .limit(1)
          .get();
      if (postQuery.docs.isNotEmpty) {
        final oName =
            postQuery.docs.first.data()['ownerName']?.toString().trim() ?? '';
        if (oName.isNotEmpty && oName.toLowerCase() != 'user') {
          return oName;
        }
      }
    } catch (_) {}
    // 7. From email address in user data
    if (data != null && data['email'] != null) {
      final formatted = _formatEmailToName(data['email'].toString());
      if (formatted.isNotEmpty && formatted.toLowerCase() != 'user') {
        return formatted;
      }
    }
    return null;
  }

  Future<Map<String, String>> getBachelorInfo(BookingModel booking) async {
    final uid = booking.bachelorUid;
    if (uid.isEmpty) {
      return {
        'name': 'Bachelor Tenant',
        'phone': booking.senderNumber.isNotEmpty
            ? booking.senderNumber
            : 'Not provided',
      };
    }
    if (userCache.containsKey(uid)) {
      return userCache[uid]!;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection(ApiConstants.usersCollection)
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        var name = data['name']?.toString().trim() ?? '';
        var phone = data['phone']?.toString().trim() ?? '';

        // If name in Firestore is empty or 'User' or 'Unknown', resolve from deeper sources
        if (name.isEmpty ||
            name.toLowerCase() == 'user' ||
            name.toLowerCase() == 'unknown') {
          final resolvedName = await _resolveRealName(uid, booking, data);
          if (resolvedName != null && resolvedName.isNotEmpty) {
            name = resolvedName;
            // Auto-fix Firestore profile so it permanently stores the real name
            FirebaseFirestore.instance
                .collection(ApiConstants.usersCollection)
                .doc(uid)
                .update({'name': name}).catchError((_) {});
          }
        }
        if (name.isEmpty ||
            name.toLowerCase() == 'user' ||
            name.toLowerCase() == 'unknown') {
          name = 'Bachelor Tenant';
        }

        // If phone in Firestore is empty or '—', use senderNumber from booking
        if (phone.isEmpty || phone == '—') {
          phone = booking.senderNumber.isNotEmpty
              ? booking.senderNumber
              : 'Not provided';
        }

        final info = {'name': name, 'phone': phone};
        userCache[uid] = info;
        return info;
      }
    } catch (e) {
      AppLogger.w('Failed to fetch user info for lead: $e',
          tag: 'LEADS_CONTROLLER');
    }
    // Fallback if user doc does not exist
    var nameFallback = 'Bachelor Tenant';
    final resolved = await _resolveRealName(uid, booking, null);
    if (resolved != null && resolved.isNotEmpty) {
      nameFallback = resolved;
    }
    final phoneFallback =
        booking.senderNumber.isNotEmpty ? booking.senderNumber : 'Not provided';
    final fallback = {'name': nameFallback, 'phone': phoneFallback};
    userCache[uid] = fallback;
    return fallback;
  }

  void copyPhoneNumber(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    Get.snackbar(
      'Copied',
      'Phone number copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  List<BookingModel> filterLeads(
    List<BookingModel> leads,
    int tabIndex,
    String query,
  ) {
    // 1. Filter by status
    final statusFiltered = leads.where((b) {
      final s = b.paymentStatus.trim().toLowerCase();
      if (tabIndex == 0) return s == 'pending';
      if (tabIndex == 1) return s == 'approved';
      return s == 'rejected';
    }).toList();

    // 2. Filter by search query (Name or Phone number)
    if (query.trim().isEmpty) {
      return statusFiltered;
    }
    final q = query.trim().toLowerCase();
    return statusFiltered.where((b) {
      final isApproved = b.isUnlocked ||
          b.paymentStatus.trim().toLowerCase() == 'approved';
      final cachedName = userCache[b.bachelorUid]?['name']?.toLowerCase() ?? '';
      final cachedPhone =
          userCache[b.bachelorUid]?['phone']?.toLowerCase() ?? '';
      final bName = b.bachelorName?.toLowerCase() ?? '';
      final bPhone = b.bachelorPhone?.toLowerCase() ?? '';

      final matchName = cachedName.contains(q) || bName.contains(q);
      final matchPhone =
          isApproved && (cachedPhone.contains(q) || bPhone.contains(q));

      return matchName || matchPhone;
    }).toList();
  }
}
