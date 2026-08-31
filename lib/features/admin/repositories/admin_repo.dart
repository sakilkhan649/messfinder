import '../../../core/services/api_service.dart';
import '../../../core/utils/api_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/models/user_model.dart';
import '../../bachelor/models/booking_model.dart';
import '../../landlord/models/post_model.dart';
import '../../payment/models/payment_model.dart';
import '../models/admin_stats_model.dart';

class AdminRepository {
  final ApiService _apiService = ApiService();

  // ─── 1. Fetch Dashboard Stats ─────────────────────────────────────────────
  Future<AdminStatsModel> getAdminStats() async {
    try {
      final response = await _apiService.dio.get(ApiConstants.adminStats);
      if (response.statusCode == 200 && response.data != null) {
        return AdminStatsModel.fromJson(response.data);
      }
      return AdminStatsModel.empty();
    } catch (e, stack) {
      AppLogger.e('Failed to fetch admin stats: $e', e, stack, 'ADMIN_REPO');
      return AdminStatsModel.empty();
    }
  }

  // ─── 2. User Management ───────────────────────────────────────────────────
  Future<List<UserModel>> getAllUsers({String? role, String? search}) async {
    try {
      final response = await _apiService.dio.get(
        ApiConstants.adminUsers,
        queryParameters: {
          if (role != null && role != 'all') 'role': role,
          if (search != null && search.isNotEmpty) 'search': search,
          't': DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) => UserModel.fromMap(json, json['uid']?.toString() ?? '')).toList();
      }
      return [];
    } catch (e, stack) {
      AppLogger.e('Failed to fetch users: $e', e, stack, 'ADMIN_REPO');
      return [];
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _apiService.dio.delete(ApiConstants.adminUserDelete(uid));
      AppLogger.s('User deleted successfully from DB: $uid', tag: 'ADMIN_REPO');
    } catch (e) {
      AppLogger.e('Error deleting user: $e', e, null, 'ADMIN_REPO');
      throw 'Failed to delete user: $e';
    }
  }

  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _apiService.dio.put(
        ApiConstants.adminUserRole(uid),
        data: {'role': role},
      );
    } catch (e) {
      throw 'Failed to update user role: $e';
    }
  }

  Future<void> updateUserStatus(String uid, String status) async {
    try {
      await _apiService.dio.put(
        ApiConstants.adminUserStatus(uid),
        data: {'status': status},
      );
    } catch (e) {
      throw 'Failed to update user status: $e';
    }
  }

  // ─── 3. Post Management ───────────────────────────────────────────────────
  Future<List<PostModel>> getAllPosts({String? status, String? search}) async {
    try {
      final response = await _apiService.dio.get(
        ApiConstants.adminPosts,
        queryParameters: {
          if (status != null && status != 'all') 'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
          't': DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) => PostModel.fromMap(json, json['post_id']?.toString() ?? '')).toList();
      }
      return [];
    } catch (e, stack) {
      AppLogger.e('Failed to fetch admin posts: $e', e, stack, 'ADMIN_REPO');
      return [];
    }
  }

  Future<void> approvePost(String postId) async {
    try {
      await _apiService.dio.put(ApiConstants.adminPostApprove(postId));
      AppLogger.s('Post approved: $postId', tag: 'ADMIN_REPO');
    } catch (e) {
      AppLogger.e('Failed to approve post: $e', e, null, 'ADMIN_REPO');
      throw 'Failed to approve post: $e';
    }
  }

  Future<void> rejectPost(String postId) async {
    try {
      await _apiService.dio.put(ApiConstants.adminPostReject(postId));
      AppLogger.s('Post rejected: $postId', tag: 'ADMIN_REPO');
    } catch (e) {
      AppLogger.e('Failed to reject post: $e', e, null, 'ADMIN_REPO');
      throw 'Failed to reject post: $e';
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _apiService.dio.delete(ApiConstants.adminPostDelete(postId));
      AppLogger.s('Post deleted: $postId', tag: 'ADMIN_REPO');
    } catch (e) {
      AppLogger.e('Failed to delete post: $e', e, null, 'ADMIN_REPO');
      throw 'Failed to delete post: $e';
    }
  }

  // ─── 4. Booking Management ────────────────────────────────────────────────
  Future<List<BookingModel>> getAllBookings({String? status, String? search}) async {
    try {
      final response = await _apiService.dio.get(
        ApiConstants.adminBookings,
        queryParameters: {
          if (status != null && status != 'all') 'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
          't': DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) {
          DateTime? createdAt;
          if (json['createdAt'] != null) {
            createdAt = DateTime.tryParse(json['createdAt'].toString());
          }
          return BookingModel(
            bookingId: json['bookingId']?.toString() ?? '',
            postId: json['postId']?.toString() ?? '',
            bachelorUid: json['bachelorUid']?.toString() ?? '',
            landlordUid: json['landlordUid']?.toString() ?? '',
            bachelorName: json['bachelorName']?.toString(),
            bachelorPhone: json['bachelorPhone']?.toString(),
            trxId: json['trxId']?.toString() ?? '',
            senderNumber: json['senderNumber']?.toString() ?? '',
            paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
            isUnlocked: json['isUnlocked'] == true,
            createdAt: createdAt,
          );
        }).toList();
      }
      return [];
    } catch (e, stack) {
      AppLogger.e('Failed to fetch admin bookings: $e', e, stack, 'ADMIN_REPO');
      return [];
    }
  }

  Future<void> approveBooking(String bookingId) async {
    try {
      await _apiService.dio.put(ApiConstants.adminBookingApprove(bookingId));
      AppLogger.s('Booking approved: $bookingId', tag: 'ADMIN_REPO');
    } catch (e) {
      AppLogger.e('Failed to approve booking: $e', e, null, 'ADMIN_REPO');
      throw 'Failed to approve booking: $e';
    }
  }

  Future<void> rejectBooking(String bookingId) async {
    try {
      await _apiService.dio.put(ApiConstants.adminBookingReject(bookingId));
      AppLogger.s('Booking rejected: $bookingId', tag: 'ADMIN_REPO');
    } catch (e) {
      AppLogger.e('Failed to reject booking: $e', e, null, 'ADMIN_REPO');
      throw 'Failed to reject booking: $e';
    }
  }

  Future<void> deleteBooking(String bookingId) async {
    try {
      await _apiService.dio.delete(ApiConstants.adminBookingDelete(bookingId));
      AppLogger.s('Booking deleted: $bookingId', tag: 'ADMIN_REPO');
    } catch (e) {
      AppLogger.e('Failed to delete booking: $e', e, null, 'ADMIN_REPO');
      throw 'Failed to delete booking: $e';
    }
  }

  // ─── 5. Payment Management ────────────────────────────────────────────────
  Future<List<PaymentModel>> getAllPayments() async {
    try {
      final response = await _apiService.dio.get(ApiConstants.adminPayments);
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) {
          DateTime? date;
          if (json['created_at'] != null) {
            date = DateTime.tryParse(json['created_at'].toString());
          }
          return PaymentModel(
            paymentId: json['payment_id']?.toString() ?? '',
            userUid: json['user_uid']?.toString() ?? '',
            userName: json['user_name']?.toString() ?? '',
            userPhone: json['user_phone']?.toString() ?? '',
            role: json['role']?.toString() ?? 'bachelor',
            amount: (json['amount'] as num?)?.toInt() ?? 50,
            trxId: json['trx_id']?.toString() ?? '',
            senderNumber: json['sender_number']?.toString() ?? '',
            paymentMethod: json['payment_method']?.toString() ?? 'bkash',
            status: json['status']?.toString() ?? 'pending',
            date: date,
          );
        }).toList();
      }
      return [];
    } catch (e, stack) {
      AppLogger.e('Failed to fetch payments: $e', e, stack, 'ADMIN_REPO');
      return [];
    }
  }

  // ─── 6. Global Broadcast Notifications ──────────────────────────────────
  Future<void> broadcastNotification({
    required String title,
    required String body,
    String targetRole = 'all',
  }) async {
    try {
      await _apiService.dio.post(
        ApiConstants.adminBroadcast,
        data: {
          'title': title,
          'body': body,
          'targetRole': targetRole,
        },
      );
      AppLogger.s('Broadcast notification sent successfully', tag: 'ADMIN_REPO');
    } catch (e) {
      AppLogger.e('Failed to broadcast notification: $e', e, null, 'ADMIN_REPO');
      throw 'Failed to send broadcast announcement: $e';
    }
  }
}
