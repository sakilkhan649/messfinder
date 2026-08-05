import '../../../core/utils/app_constants.dart';
import '../../bachelor/models/booking_model.dart';
import '../../landlord/models/post_model.dart';

/// ===================================================================
/// [MODEL LAYER - MVC PATTERN]
/// AdminStatsModel: অ্যাডমিন ড্যাশবোর্ডের সব ধরনের পরিসংখ্যান (Statistics)
/// এবং রেভিনিউ (Revenue) হিসাব সংরক্ষণ ও নিয়ন্ত্রণ করে।
/// 
/// View (UI) কোনো প্রকার জটিল হিসাব বা লজিক চালাবে না, View শুধুমাত্র
/// এই মডেল থেকে ডেটা নিয়ে প্রদর্শন করবে।
/// ===================================================================
class AdminStatsModel {
  // ─── ব্যাচেলর বুকিং পরিসংখ্যান (Bachelor Booking Statistics) ───
  final int pendingBookings;
  final int approvedBookings;
  final int rejectedBookings;

  // ─── মেস লিস্টিং পোস্ট পরিসংখ্যান (Mess Listing Post Statistics) ───
  final int pendingPosts;
  final int approvedPosts;
  final int rejectedPosts;

  // ─── সর্বমোট পরিসংখ্যান (Total Counts) ───
  final int totalPending;
  final int totalApproved;
  final int totalRejected;

  // ─── আয় ও রেভিনিউ পরিসংখ্যান (Revenue Calculation) ───
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

  /// Factory constructor: বুকিং এবং পোস্টের লিস্ট থেকে স্বয়ংক্রিয়ভাবে
  /// সব পরিসংখ্যান ও রেভিনিউ হিসাব করে [AdminStatsModel] তৈরি করে।
  factory AdminStatsModel.fromData({
    required List<BookingModel> bookings,
    required List<PostModel> posts,
  }) {
    // ব্যাচেলর বুকিং গণনা
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

    // মেস পোস্ট গণনা
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

    // সর্বমোট গণনা
    final totalPen = pendingB + pendingP;
    final totalApp = approvedB + approvedP;
    final totalRej = rejectedB + rejectedP;

    // আয় (Revenue) গণনা
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

  /// শূন্য বা প্রাথমিক অবস্থার পরিসংখ্যান (Empty state for initial loading)
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
