import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/api_constants.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repo.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const skyBlue = Color(0xFF0EA5E9);
    const darkBlue = Color(0xFF0369A1);

    final auth = Get.find<AuthController>();
    final uid = auth.currentUser.value?.uid ?? '';
    final repo = BookingRepository();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: darkBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'My Bookings',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: uid.isEmpty
          ? Center(
              child: Text(
                'Please log in to view your bookings.',
                style: GoogleFonts.poppins(
                    fontSize: 14.sp, color: AppTheme.textSecondary),
              ),
            )
          : StreamBuilder<List<BookingModel>>(
              stream: repo.getBookingsForBachelor(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(color: skyBlue));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 48.r, color: Colors.redAccent),
                        SizedBox(height: 12.h),
                        Text(
                          'Failed to load bookings.',
                          style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                final bookings = snapshot.data ?? [];

                if (bookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.book_online_outlined,
                            size: 72.r, color: const Color(0xFFCBD5E1)),
                        SizedBox(height: 16.h),
                        Text(
                          'No bookings yet',
                          style: GoogleFonts.poppins(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Your room booking requests\nwill appear here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final pending = bookings
                    .where((b) =>
                        b.paymentStatus.trim().toLowerCase() == 'pending')
                    .length;
                final approved = bookings
                    .where((b) =>
                        b.paymentStatus.trim().toLowerCase() == 'approved')
                    .length;

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                      horizontal: 20.w, vertical: 16.h),
                  children: [
                    // Summary Banner
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            darkBlue.withValues(alpha: 0.10),
                            skyBlue.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                            color: skyBlue.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.book_online_rounded,
                                  color: skyBlue, size: 22.r),
                              SizedBox(width: 10.w),
                              Text(
                                '${bookings.length} total request${bookings.length == 1 ? '' : 's'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              _StatusChip(
                                label: '⏳ Pending',
                                count: pending,
                                bg: const Color(0xFFFEF3C7),
                                color: const Color(0xFFB45309),
                              ),
                              SizedBox(width: 8.w),
                              _StatusChip(
                                label: '✅ Approved',
                                count: approved,
                                bg: const Color(0xFFD1FAE5),
                                color: const Color(0xFF047857),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 18.h),
                    ...bookings.map((b) => _BookingCard(booking: b)),
                  ],
                );
              },
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color bg;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.bg,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        '$label ($count)',
        style: GoogleFonts.poppins(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _BookingCard extends StatefulWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  String _postTitle = '...';
  String _postAddress = '...';
  double _postRent = 0;

  static const skyBlue = Color(0xFF0EA5E9);

  @override
  void initState() {
    super.initState();
    _fetchPostInfo();
  }

  Future<void> _fetchPostInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(ApiConstants.postsCollection)
          .doc(widget.booking.postId)
          .get();
      if (mounted && doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _postTitle = data['title']?.toString() ?? 'Unknown Room';
          _postAddress = data['address']?.toString() ?? '—';
          _postRent = (data['rent'] ?? 0).toDouble();
        });
      } else if (mounted) {
        setState(() {
          _postTitle = 'Room not found';
          _postAddress = '—';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _postTitle = 'Room info unavailable');
      }
    }
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return '✅ Approved';
      case 'rejected':
        return '❌ Rejected';
      default:
        return '⏳ Pending Review';
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return const Color(0xFF059669);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Color _statusBg(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return const Color(0xFFD1FAE5);
      case 'rejected':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFFEF3C7);
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return 'Recently';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final isApproved = b.paymentStatus.trim().toLowerCase() == 'approved';
    final isRejected = b.paymentStatus.trim().toLowerCase() == 'rejected';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14.r,
            offset: Offset(0, 4.h),
          ),
        ],
        border: Border.all(
          color: isApproved
              ? const Color(0xFFA7F3D0)
              : (isRejected
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFE2E8F0)),
          width: isApproved || isRejected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: _statusBg(b.paymentStatus),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(18.r)),
            ),
            child: Row(
              children: [
                Text(
                  _statusLabel(b.paymentStatus),
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: _statusColor(b.paymentStatus),
                  ),
                ),
                const Spacer(),
                Text(
                  _timeAgo(b.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: _statusColor(b.paymentStatus)
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Title
                Row(
                  children: [
                    Icon(Icons.home_work_rounded,
                        size: 18.r, color: skyBlue),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _postTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_postRent > 0)
                      Text(
                        '৳${_postRent.toInt()}/mo',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: skyBlue,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 14.r,
                        color: Colors.grey.shade500),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        _postAddress,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Divider(height: 1, color: const Color(0xFFF1F5F9)),
                SizedBox(height: 10.h),

                // Payment info
                Row(
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        size: 14.r, color: Colors.grey.shade500),
                    SizedBox(width: 6.w),
                    Text(
                      'TrxID: ${b.trxId.isNotEmpty ? b.trxId : "—"}',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.phone_rounded,
                        size: 14.r, color: Colors.grey.shade500),
                    SizedBox(width: 6.w),
                    Text(
                      'Sent from: ${b.senderNumber.isNotEmpty ? b.senderNumber : "—"}',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),

                // Approved unlocked note
                if (isApproved) ...[
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                          color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_open_rounded,
                            size: 16.r,
                            color: const Color(0xFF059669)),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '🎉 Your booking is approved! Contact the landlord to confirm your room.',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF047857),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Rejected note
                if (isRejected) ...[
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                          color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16.r,
                            color: const Color(0xFFEF4444)),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Booking was not approved. Please try another room.',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
