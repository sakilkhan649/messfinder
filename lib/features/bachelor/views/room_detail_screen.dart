import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mess_finder/features/chat/controllers/chat_controller.dart';
import 'package:mess_finder/features/chat/views/chat_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/widgets/premium_payment_dialog.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../landlord/controllers/post_controller.dart';
import '../../landlord/models/post_model.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repo.dart';

class RoomDetailScreen extends StatelessWidget {
  final PostModel post;

  const RoomDetailScreen({super.key, required this.post});

  void _requestPaymentAndUnlock(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final user = authCtrl.currentUser.value;
    if (user == null) {
      Get.snackbar('Error', 'Please login first');
      return;
    }
    PremiumPaymentDialog.show(
      context,
      isLandlord: false,
      onPaymentSubmitted: (trxId, senderNumber) async {
        try {
          final booking = BookingModel(
            bookingId: '',
            postId: post.postId,
            bachelorUid: user.uid,
            landlordUid: post.ownerUid,
            paymentStatus: 'pending',
            trxId: trxId,
            senderNumber: senderNumber,
            isUnlocked: false,
            createdAt: DateTime.now(),
            bachelorName: (user.name != 'User' && user.name.isNotEmpty)
                ? user.name
                : 'Bachelor Tenant',
            bachelorPhone:
                user.phone.isNotEmpty ? user.phone : senderNumber,
          );
          await BookingRepository().createBooking(booking);
          Get.snackbar(
            'Booking Request Submitted! ⏳',
            'Once Admin verifies your payment, the landlord number will be unlocked and you can call or book directly.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFF59E0B),
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        } catch (e) {
          Get.snackbar('Error', e.toString());
        }
      },
    );
  }

  Future<void> _callLandlord(
      BuildContext context, bool isUnlocked, bool isPending) async {
    if (isUnlocked) {
      final phone = post.ownerPhone ?? '01700000000';
      final Uri url = Uri.parse('tel:$phone');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        Get.snackbar('Error', 'Unable to initiate call');
      }
    } else if (isPending) {
      Get.snackbar(
        'Booking Request Pending ⏳',
        'Your payment is awaiting admin verification. Once verified, you can view the number and call.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF59E0B),
        colorText: Colors.white,
      );
    } else {
      _requestPaymentAndUnlock(context);
    }
  }

  Future<void> _messageLandlord(
      BuildContext context, bool isUnlocked, bool isPending) async {
    if (isUnlocked) {
      if (post.ownerUid.isNotEmpty) {
        final chatController = Get.put(ChatController());
        final roomId = await chatController.createOrGetChatRoom(
          post.ownerUid,
          '',
          null,
        );
        Get.to(() => ChatScreen(
          chatRoomId: roomId,
          targetUserId: post.ownerUid,
          targetUserName: 'Landlord',
        ));
      } else {
        Get.snackbar('Error', 'Landlord ID not found.');
      }
    } else if (isPending) {
      Get.snackbar(
        'Booking Request Pending ⏳',
        'Your payment is awaiting admin verification. Once verified, you can view the number and send SMS.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF59E0B),
        colorText: Colors.white,
      );
    } else {
      _requestPaymentAndUnlock(context);
    }
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.report_problem_rounded, color: Colors.red.shade600),
            SizedBox(width: 8.w),
            const Text('Report Listing'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If there is incorrect information or an issue with this listing, report it below. Posts with multiple reports are reviewed by Admin.',
              style: GoogleFonts.poppins(fontSize: 13.sp),
            ),
            SizedBox(height: 12.h),
            _buildReportOption(ctx, 'Fake address or photo'),
            _buildReportOption(ctx, 'Phone number invalid or unreachable'),
            _buildReportOption(ctx, 'Incorrect rent amount'),
            _buildReportOption(ctx, 'Scam or misleading post'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOption(BuildContext context, String reason) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading:
          Icon(Icons.flag_outlined, size: 20.r, color: Colors.red.shade400),
      title: Text(reason, style: GoogleFonts.poppins(fontSize: 13.sp)),
      onTap: () {
        Navigator.pop(context);
        Get.snackbar(
          'Report Submitted ⚠️',
          '"$reason" has been reported to Admin for review. Thank you!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
        );
      },
    );
  }

  void _bookRoom(
      BuildContext context, bool isUnlocked, bool isPending) {
    if (isPending) {
      Get.snackbar(
        'Booking Request Pending ⏳',
        'Your booking request is currently awaiting admin verification.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF59E0B),
        colorText: Colors.white,
      );
    } else if (isUnlocked) {
      Get.snackbar(
        'Already Booked ✅',
        'You have already booked this mess room. You can call or send SMS directly.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
      );
    } else {
      _requestPaymentAndUnlock(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF1E1B4B); // Deep Indigo
    final Color accentColor = const Color(0xFFF59E0B); // Warm Amber Gold

    final String genderText = post.bachelorType == 'female'
        ? 'Female Only'
        : post.bachelorType == 'both'
            ? 'Any Bachelor'
            : 'Male Only';

    final authCtrl = Get.find<AuthController>();
    final user = authCtrl.currentUser.value;
    final stream = (user != null && user.uid.isNotEmpty)
        ? BookingRepository().getBookingStreamForPost(post.postId, user.uid)
        : Stream.value(<BookingModel>[]);

    return StreamBuilder<List<BookingModel>>(
      stream: stream,
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? [];
        final isUnlocked =
            bookings.any((b) => b.isUnlocked && b.paymentStatus == 'approved');
        final isPending =
            bookings.any((b) => !b.isUnlocked && b.paymentStatus == 'pending');

        final fullPhone = post.ownerPhone ?? '01712345678';
        final maskedPhone = fullPhone.length > 5
            ? '${fullPhone.substring(0, 5)}******'
            : '01711******';
        final displayPhone = isUnlocked ? fullPhone : maskedPhone;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280.h,
                pinned: true,
                backgroundColor: primaryColor,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  Obx(() {
                    final postCtrl = Get.find<PostController>();
                    final isFav = postCtrl.isSaved(post.postId);
                    return Container(
                      margin: EdgeInsets.only(right: 8.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => postCtrl.toggleSavePost(post.postId),
                        icon: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav ? Colors.redAccent : Colors.white,
                          size: 24.r,
                        ),
                        tooltip: 'Save to Favorites',
                      ),
                    );
                  }),
                  Container(
                    margin: EdgeInsets.only(right: 12.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => _showReportDialog(context),
                      icon: Icon(
                        Icons.flag_outlined,
                        color: Colors.amberAccent,
                        size: 24.r,
                      ),
                      tooltip: 'Report Listing',
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      post.images.isNotEmpty
                          ? AppImageHelper.buildImage(
                              post.images.first,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.home_work_rounded,
                                  size: 80, color: Colors.grey),
                            ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.75),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16.h,
                        right: 20.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(24.r),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.4),
                                blurRadius: 10.r,
                              ),
                            ],
                          ),
                          child: Text(
                            '৳${post.rent.toInt()} / mo',
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Location
                      Text(
                        post.title,
                        style: GoogleFonts.poppins(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 18.r, color: accentColor),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              post.address,
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      
                      // Tags Group
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          // Gender Tag
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: post.bachelorType.toLowerCase() == 'male'
                                  ? Colors.blue.withValues(alpha: 0.1)
                                  : post.bachelorType.toLowerCase() == 'female'
                                      ? Colors.pink.withValues(alpha: 0.1)
                                      : Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: post.bachelorType.toLowerCase() == 'male'
                                    ? Colors.blue.withValues(alpha: 0.3)
                                    : post.bachelorType.toLowerCase() == 'female'
                                        ? Colors.pink.withValues(alpha: 0.3)
                                        : Colors.purple.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  post.bachelorType.toLowerCase() == 'male'
                                      ? Icons.male_rounded
                                      : post.bachelorType.toLowerCase() == 'female'
                                          ? Icons.female_rounded
                                          : Icons.people_rounded,
                                  size: 14.r,
                                  color: post.bachelorType.toLowerCase() == 'male'
                                      ? Colors.blue.shade700
                                      : post.bachelorType.toLowerCase() == 'female'
                                          ? Colors.pink.shade700
                                          : Colors.purple.shade700,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  genderText,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: post.bachelorType.toLowerCase() == 'male'
                                        ? Colors.blue.shade700
                                        : post.bachelorType.toLowerCase() == 'female'
                                            ? Colors.pink.shade700
                                            : Colors.purple.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Seats Tag
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.single_bed_rounded, size: 14.r, color: Colors.green.shade700),
                                SizedBox(width: 4.w),
                                Text(
                                  'Seats: ${post.displaySeats}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Preferred Tag
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.school_rounded, size: 14.r, color: accentColor),
                                SizedBox(width: 4.w),
                                Text(
                                  post.preferredTenant,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'Available Facilities',
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: post.facilities.toSet().toList().map((facility) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 14.r, color: primaryColor),
                                SizedBox(width: 6.w),
                                Text(
                                  facility,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 24.h),

                      // Landlord / Manager Info
                      Text(
                        'Contact & Location',
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24.r,
                              backgroundColor: primaryColor.withValues(alpha: 0.1),
                              child: Icon(Icons.person, color: primaryColor, size: 26.r),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Landlord / Manager',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.sp,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    displayPhone,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  if (isUnlocked)
                                    Container(
                                      margin: EdgeInsets.only(top: 4.h),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Text(
                                        'Verified Number Unlocked ✅',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10.sp,
                                          color: const Color(0xFF10B981),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else if (isPending)
                                    Container(
                                      margin: EdgeInsets.only(top: 4.h),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Text(
                                        'Booking Request Pending ⏳',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10.sp,
                                          color: const Color(0xFFB45309),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      margin: EdgeInsets.only(top: 4.h),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Text(
                                        'Pay ৳50 to unlock phone number & book 🔒',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10.sp,
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 100.h),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Direct Contact Action Buttons
          bottomNavigationBar: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10.r,
                  offset: Offset(0, -4.h),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Call button
                  Container(
                    height: 48.h,
                    width: 48.h,
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: IconButton(
                      onPressed: () =>
                          _callLandlord(context, isUnlocked, isPending),
                      icon: Icon(Icons.call_rounded,
                          color: primaryColor, size: 22.r),
                      tooltip: 'Call Landlord',
                    ),
                  ),
                  // Message button
                  Container(
                    height: 48.h,
                    width: 48.h,
                    margin: EdgeInsets.only(right: 10.w),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: IconButton(
                      onPressed: () =>
                          _messageLandlord(context, isUnlocked, isPending),
                      icon: Icon(Icons.message_rounded,
                          color: primaryColor, size: 22.r),
                      tooltip: 'Send SMS',
                    ),
                  ),
                  // Booking Button (Main Action)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _bookRoom(context, isUnlocked, isPending),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      icon: const Icon(Icons.home_work_rounded,
                          color: Colors.white),
                      label: Text(
                        'Book Room Now',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
