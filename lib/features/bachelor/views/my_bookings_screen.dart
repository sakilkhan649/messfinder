import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mess_finder/features/chat/controllers/chat_controller.dart';
import 'package:mess_finder/features/chat/views/chat_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/api_constants.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repo.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF059669); // Deep Indigo

    final auth = Get.find<AuthController>();
    final uid = auth.currentUser.value?.uid ?? '';
    final repo = BookingRepository();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20.r),
          onPressed: () => Get.back(),
        ),
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
                      child: CircularProgressIndicator(color: primaryColor));
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
                  return RefreshIndicator(
                    color: primaryColor,
                    onRefresh: () async {
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        alignment: Alignment.center,
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
                      ),
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

                return RefreshIndicator(
                  color: primaryColor,
                  onRefresh: () async {
                    // For StreamBuilder, a pull to refresh mostly just gives UI feedback
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: EdgeInsets.symmetric(
                        horizontal: 20.w, vertical: 16.h),
                    children: [
                      // Summary Banner
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.10),
                            primaryColor.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                            color: primaryColor.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.book_online_rounded,
                                  color: primaryColor, size: 22.r),
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
                ),
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
  String _ownerPhone = '';
  String _ownerName = 'Loading...';
  String? _ownerPhotoUrl;
  String _ownerUid = '';

  final Color primaryColor = const Color(0xFF059669);

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
        
        String ownerUid = data['ownerUid']?.toString() ?? '';
        String ownerName = 'Unknown Landlord';
        String? ownerPhoto;
        
        if (ownerUid.isNotEmpty) {
          final userDoc = await FirebaseFirestore.instance
              .collection(ApiConstants.usersCollection)
              .doc(ownerUid)
              .get();
          if (userDoc.exists && userDoc.data() != null) {
            ownerName = userDoc.data()!['name']?.toString() ?? 'Unknown Landlord';
            ownerPhoto = userDoc.data()!['photoUrl']?.toString();
          }
        }

        setState(() {
          _postTitle = data['title']?.toString() ?? 'Unknown Room';
          _postAddress = data['address']?.toString() ?? '—';
          _postRent = (data['rent'] ?? 0).toDouble();
          _ownerPhone = data['ownerPhone']?.toString() ?? '';
          _ownerName = ownerName;
          _ownerPhotoUrl = ownerPhoto;
          _ownerUid = ownerUid;
        });
      } else if (mounted) {
        setState(() {
          _postTitle = 'Room not found';
          _postAddress = '—';
          _ownerName = 'Unknown';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _postTitle = 'Room info unavailable';
          _ownerName = 'Unknown';
        });
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
        return primaryColor;
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Color _statusBg(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return primaryColor.withValues(alpha: 0.08);
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

    return Dismissible(
      key: Key(b.bookingId),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        BookingRepository().deleteBooking(b.bookingId);
        Get.snackbar(
          'Deleted',
          'Booking record removed successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
        );
      },
      background: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(18.r),
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28.r),
      ),
      secondaryBackground: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(18.r),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28.r),
      ),
      child: Container(
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
                ? primaryColor.withValues(alpha: 0.3)
                : (isRejected
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFFFDE68A)),
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
                    color: _statusColor(b.paymentStatus).withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
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
                // Landlord Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18.r,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _ownerPhotoUrl != null && _ownerPhotoUrl!.isNotEmpty
                          ? NetworkImage(_ownerPhotoUrl!)
                          : null,
                      child: _ownerPhotoUrl == null || _ownerPhotoUrl!.isEmpty
                          ? Icon(Icons.person_rounded, size: 20.r, color: Colors.grey.shade500)
                          : null,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _ownerName,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Landlord',
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Divider(height: 1, color: const Color(0xFFF1F5F9)),
                SizedBox(height: 12.h),
                
                // Room Title
                Row(
                  children: [
                    Icon(Icons.home_work_rounded,
                        size: 18.r, color: primaryColor),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _postTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_postRent > 0)
                      Text(
                        'Tk.${_postRent.toInt()}/mo',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
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
                        horizontal: 12.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                          color: primaryColor.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock_open_rounded,
                                size: 16.r,
                                color: primaryColor),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                '🎉 Your booking is approved!',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (_ownerPhone.isEmpty) return;
                                  final url = Uri.parse('tel:$_ownerPhone');
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                icon: Icon(Icons.call_rounded, size: 16.r),
                                label: FittedBox(child: Text('Call', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (_ownerUid.isNotEmpty) {
                                    final chatController = Get.find<ChatController>();
                                    // Use a loading dialog if needed, but for now just navigate quickly
                                    final roomId = await chatController.createOrGetChatRoom(
                                      _ownerUid,
                                      _ownerName,
                                      _ownerPhotoUrl,
                                    );
                                    Get.to(() => ChatScreen(
                                      chatRoomId: roomId,
                                      targetUserId: _ownerUid,
                                      targetUserName: _ownerName,
                                    ));
                                  } else {
                                    Get.snackbar('Error', 'Landlord ID not found.');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: primaryColor,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    side: BorderSide(color: primaryColor),
                                  ),
                                ),
                                icon: Icon(Icons.message_rounded, size: 16.r),
                                label: FittedBox(child: Text('Message', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                              ),
                            ),
                          ],
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
    ),
    );
  }
}
