import '../../../core/utils/app_constants.dart';
import '../../bachelor/models/booking_model.dart';
import '../../landlord/models/post_model.dart';

/// ===================================================================
/// [MODEL LAYER - MVC PATTERN]
/// 
/// ===================================================================
class AdminStatsModel {
  final int pendingBookings;
  final int approvedBookings;
  final int rejectedBookings;

  final int pendingPosts;
  final int approvedPosts;
  final int rejectedPosts;

  final int totalPending;
  final int totalApproved;
  final int totalRejected;

  final int bookingRevenue;
  final int postRevenue;
  final int totalRevenue;

  const AdminStatsModel({
    required this.pendingBookings,
    required this.approvedBookings,
    required this.rejectedBookings,
    required this.pendingPosts,
    required this.approvedPosts,
    required this.rejectedPosts,
    required this.totalPending,
    required this.totalApproved,
    required this.totalRejected,
    required this.bookingRevenue,
    required this.postRevenue,
    required this.totalRevenue,
  });

  factory AdminStatsModel.fromData({
    required List<BookingModel> bookings,
    required List<PostModel> posts,
  }) {
    final pendingB = bookings
        .where((b) => b.paymentStatus.trim().toLowerCase() == 'pending')
        .length;
    final approvedB = bookings
        .where((b) =>
            b.paymentStatus.trim().toLowerCase() == 'approved' ||
            b.isUnlocked == true)
        .length;
    final rejectedB = bookings
        .where((b) => b.paymentStatus.trim().toLowerCase() == 'rejected')
        .length;

    final pendingP = posts
        .where((p) => p.paymentStatus.trim().toLowerCase() == 'pending')
        .length;
    final approvedP = posts
        .where((p) =>
            p.paymentStatus.trim().toLowerCase() == 'approved' ||
            p.isPublished == true)
        .length;
    final rejectedP = posts
        .where((p) => p.paymentStatus.trim().toLowerCase() == 'rejected')
        .length;

    final totalPen = pendingB + pendingP;
    final totalApp = approvedB + approvedP;
    final totalRej = rejectedB + rejectedP;

    final bRevenue = approvedB * AppConstants.bachelorFee;
    final pRevenue = approvedP * AppConstants.landlordFee;
    final tRevenue = bRevenue + pRevenue;

    return AdminStatsModel(
      pendingBookings: pendingB,
      approvedBookings: approvedB,
      rejectedBookings: rejectedB,
      pendingPosts: pendingP,
      approvedPosts: approvedP,
      rejectedPosts: rejectedP,
      totalPending: totalPen,
      totalApproved: totalApp,
      totalRejected: totalRej,
      bookingRevenue: bRevenue,
      postRevenue: pRevenue,
      totalRevenue: tRevenue,
    );
  }

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    final posts = json['posts'] as Map<String, dynamic>? ?? {};
    final bookings = json['bookings'] as Map<String, dynamic>? ?? {};
    final summary = json['summary'] as Map<String, dynamic>? ?? {};

    final pendingB = (bookings['pending'] as num?)?.toInt() ?? 0;
    final approvedB = (bookings['approved'] as num?)?.toInt() ?? 0;
    final rejectedB = (bookings['rejected'] as num?)?.toInt() ?? 0;

    final pendingP = (posts['pending'] as num?)?.toInt() ?? 0;
    final approvedP = (posts['approved'] as num?)?.toInt() ?? 0;
    final rejectedP = (posts['rejected'] as num?)?.toInt() ?? 0;

    final totalPen = (summary['totalPending'] as num?)?.toInt() ?? (pendingB + pendingP);
    final totalApp = (summary['totalApproved'] as num?)?.toInt() ?? (approvedB + approvedP);
    final totalRej = (summary['totalRejected'] as num?)?.toInt() ?? (rejectedB + rejectedP);

    final bRevenue = (json['bookingRevenue'] as num?)?.toInt() ?? (approvedB * AppConstants.bachelorFee);
    final pRevenue = (json['postRevenue'] as num?)?.toInt() ?? (approvedP * AppConstants.landlordFee);
    final tRevenue = (json['totalRevenue'] as num?)?.toInt() ?? (bRevenue + pRevenue);

    return AdminStatsModel(
      pendingBookings: pendingB,
      approvedBookings: approvedB,
      rejectedBookings: rejectedB,
      pendingPosts: pendingP,
      approvedPosts: approvedP,
      rejectedPosts: rejectedP,
      totalPending: totalPen,
      totalApproved: totalApp,
      totalRejected: totalRej,
      bookingRevenue: bRevenue,
      postRevenue: pRevenue,
      totalRevenue: tRevenue,
    );
  }

  factory AdminStatsModel.empty() {
    return const AdminStatsModel(
      pendingBookings: 0,
      approvedBookings: 0,
      rejectedBookings: 0,
      pendingPosts: 0,
      approvedPosts: 0,
      rejectedPosts: 0,
      totalPending: 0,
      totalApproved: 0,
      totalRejected: 0,
      bookingRevenue: 0,
      postRevenue: 0,
      totalRevenue: 0,
    );
  }
}
