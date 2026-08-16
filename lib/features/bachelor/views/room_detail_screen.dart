import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../notifications/views/widgets/notification_bell_action.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../landlord/controllers/post_controller.dart';
import '../../landlord/models/post_model.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repo.dart';
import 'widgets/facebook_image_grid.dart';
import '../../auth/models/user_model.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../chat/views/chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/location_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../profile/views/public_profile_screen.dart';
import '../../chat/views/widgets/video_player_widget.dart';

class RoomDetailScreen extends StatelessWidget {
  final PostModel post;

  const RoomDetailScreen({super.key, required this.post});

  void _generateLead(UserModel user) async {
    try {
      final booking = BookingModel(
        bookingId: '',
        postId: post.postId,
        bachelorUid: user.uid,
        landlordUid: post.ownerUid,
        paymentStatus: 'approved',
        trxId: 'Free Tier',
        senderNumber: 'N/A',
        isUnlocked: true,
        createdAt: DateTime.now(),
        bachelorName: (user.name != 'User' && user.name.isNotEmpty)
            ? user.name
            : 'Bachelor Tenant',
        bachelorPhone: user.phone.isNotEmpty ? user.phone : 'N/A',
      );
      await BookingRepository().createBooking(booking);
    } catch (e) {
      // Silently fail if lead generation fails, we don't want to block the user
    }
  }

  void _makeCall(BuildContext context) async {
    final authCtrl = Get.find<AuthController>();
    final user = authCtrl.currentUser.value;
    if (user == null) {
      Get.snackbar(
        'Login Required',
        'Please login first to call the landlord',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final phone = post.ownerPhone;
    if (phone == null || phone.isEmpty) {
      Get.snackbar(
        'Unavailable',
        'Landlord has not provided a phone number.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _generateLead(user);

    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        Get.snackbar(
          'Error',
          'Could not open dialer.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not open dialer.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _startChat(BuildContext context) async {
    final authCtrl = Get.find<AuthController>();
    final user = authCtrl.currentUser.value;
    if (user == null) {
      Get.snackbar(
        'Login Required',
        'Please login first to message the landlord',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _generateLead(user);

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final chatCtrl = Get.put(ChatController());
      final chatRoomId = await chatCtrl.createOrGetChatRoom(
        post.ownerUid,
        'Loading...',
        null,
      );
      Get.back(); // close loading dialog

      Get.to(
        () => ChatScreen(
          chatRoomId: chatRoomId,
          targetUserId: post.ownerUid,
          targetUserName: 'Loading...',
          targetUserPhoto: null,
        ),
      );
    } catch (e) {
      Get.back(); // close dialog
      Get.snackbar(
        'Error',
        'Failed to start chat',
        snackPosition: SnackPosition.BOTTOM,
      );
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
      leading: Icon(
        Icons.flag_outlined,
        size: 20.r,
        color: Colors.red.shade400,
      ),
      title: Text(reason, style: GoogleFonts.poppins(fontSize: 13.sp)),
      onTap: () async {
        Navigator.pop(context);
        try {
          final authCtrl = Get.find<AuthController>();
          final user = authCtrl.currentUser.value;
          if (user != null) {
            await FirebaseFirestore.instance.collection('reports').add({
              'postId': post.postId,
              'reporterUid': user.uid,
              'reporterName': user.name,
              'reason': reason,
              'createdAt': FieldValue.serverTimestamp(),
              'status': 'pending',
            });
            Get.snackbar(
              'Report Submitted ⚠️',
              '"$reason" has been reported to Admin for review. Thank you!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red.shade600,
              colorText: Colors.white,
            );
          }
        } catch (e) {
          Get.snackbar('Error', 'Failed to submit report.');
        }
      },
    );
  }

  // Replaced _handleContactClick with _makeCall and _startChat

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF059669); // Deep Indigo
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

    final isMyPost = user != null && user.uid == post.ownerUid;

    return StreamBuilder<List<BookingModel>>(
      stream: stream,
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? [];
        final isUnlocked = bookings.any(
          (b) => b.isUnlocked && b.paymentStatus == 'approved',
        );

        final fullPhone = post.ownerPhone ?? '01712345678';
        final maskedPhone = fullPhone.length > 5
            ? '${fullPhone.substring(0, 5)}******'
            : '01711******';
        final displayPhone = isUnlocked ? fullPhone : maskedPhone;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: RefreshIndicator(
            color: primaryColor,
            onRefresh: () async {
              await Get.find<PostController>().refreshPosts();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
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
                    Container(
                      margin: EdgeInsets.only(right: 12.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const NotificationBellAction(),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        post.images.isNotEmpty
                            ? FacebookImageGrid(
                                images: post.images,
                                height: 280,
                              )
                            : Container(
                                color: Colors.grey.shade300,
                                child: const Icon(
                                  Icons.home_work_rounded,
                                  size: 80,
                                  color: Colors.grey,
                                ),
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
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
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
                              'Tk.${post.rent.toInt()} / mo',
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
                        if (post.videoUrl != null && post.videoUrl!.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: SizedBox(
                              height: 250.h,
                              width: double.infinity,
                              child: VideoPlayerWidget(videoUrl: post.videoUrl!),
                            ),
                          ),
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
                            Icon(
                              Icons.location_on_rounded,
                              size: 18.r,
                              color: accentColor,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Obx(() {
                                final postCtrl = Get.find<PostController>();
                                final pos = postCtrl.userLocation.value;
                                String distanceText = '';
                                if (pos != null) {
                                  final distKm =
                                      LocationService.calculateDistanceInKm(
                                        pos.latitude,
                                        pos.longitude,
                                        post.latitude,
                                        post.longitude,
                                      );
                                  if (distKm < 1.0) {
                                    distanceText =
                                        '\n📍 ${(distKm * 1000).toInt()}m away from you';
                                  } else {
                                    distanceText =
                                        '\n📍 ${distKm.toStringAsFixed(1)}km away from you';
                                  }
                                }
                                return Text(
                                  '${post.address}$distanceText',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }),
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: post.bachelorType.toLowerCase() == 'male'
                                    ? Colors.blue.withValues(alpha: 0.1)
                                    : post.bachelorType.toLowerCase() ==
                                          'female'
                                    ? Colors.pink.withValues(alpha: 0.1)
                                    : Colors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color:
                                      post.bachelorType.toLowerCase() == 'male'
                                      ? Colors.blue.withValues(alpha: 0.3)
                                      : post.bachelorType.toLowerCase() ==
                                            'female'
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
                                        : post.bachelorType.toLowerCase() ==
                                              'female'
                                        ? Icons.female_rounded
                                        : Icons.people_rounded,
                                    size: 14.r,
                                    color:
                                        post.bachelorType.toLowerCase() ==
                                            'male'
                                        ? Colors.blue.shade700
                                        : post.bachelorType.toLowerCase() ==
                                              'female'
                                        ? Colors.pink.shade700
                                        : Colors.purple.shade700,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    genderText,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          post.bachelorType.toLowerCase() ==
                                              'male'
                                          ? Colors.blue.shade700
                                          : post.bachelorType.toLowerCase() ==
                                                'female'
                                          ? Colors.pink.shade700
                                          : Colors.purple.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Seats Tag
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.single_bed_rounded,
                                    size: 14.r,
                                    color: Colors.green.shade700,
                                  ),
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.school_rounded,
                                    size: 14.r,
                                    color: accentColor,
                                  ),
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
                          children: post.facilities.toSet().toList().map((
                            facility,
                          ) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 14.r,
                                    color: primaryColor,
                                  ),
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
                        FutureBuilder<Map<String, dynamic>?>(
                          initialData: Get.find<PostController>()
                              .landlordProfilesCache[post.ownerUid],
                          future:
                              Get.find<PostController>().landlordProfilesCache
                                  .containsKey(post.ownerUid)
                              ? null
                              : Get.find<PostController>().getLandlordProfile(
                                  post.ownerUid,
                                ),
                          builder: (context, snapshot) {
                            final profile = snapshot.data;
                            final name =
                                profile?['name']?.toString() ??
                                'Landlord / Manager';
                            final photoUrl = profile?['photoUrl']?.toString();
                            final isPaid = profile?['isPaid'] ?? false;

                            return GestureDetector(
                              onTap: () {
                                Get.to(() => PublicProfileScreen(userId: post.ownerUid));
                              },
                              child: Container(
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
                                    backgroundColor: primaryColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    backgroundImage:
                                        (photoUrl != null &&
                                            photoUrl.isNotEmpty)
                                        ? NetworkImage(photoUrl)
                                        : null,
                                    child:
                                        (photoUrl == null || photoUrl.isEmpty)
                                        ? Icon(
                                            Icons.person,
                                            color: primaryColor,
                                            size: 26.r,
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: 14.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                name,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12.sp,
                                                  color: AppTheme.textSecondary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isPaid) ...[
                                              SizedBox(width: 4.w),
                                              Icon(
                                                Icons.verified_rounded,
                                                color: Colors.blue,
                                                size: 14.r,
                                              ),
                                            ],
                                          ],
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
                                              horizontal: 8.w,
                                              vertical: 2.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF10B981,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6.r),
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
                                        else
                                          Container(
                                            margin: EdgeInsets.only(top: 4.h),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.w,
                                              vertical: 2.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6.r),
                                            ),
                                            child: Text(
                                              'Click "Get Contact" to unlock number 🔒',
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
                            );
                          },
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'Location Map',
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Container(
                          height: 200.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(post.latitude, post.longitude),
                                zoom: 15,
                              ),
                              markers: {
                                Marker(
                                  markerId: MarkerId(post.postId),
                                  position: LatLng(post.latitude, post.longitude),
                                  infoWindow: InfoWindow(title: post.title),
                                ),
                              },
                              zoomControlsEnabled: false,
                              myLocationEnabled: false,
                              compassEnabled: false,
                              mapToolbarEnabled: false,
                            ),
                          ),
                        ),
                        SizedBox(height: 100.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Direct Contact Action Buttons
          bottomNavigationBar: isMyPost
              ? const SizedBox.shrink()
              : Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 14.h,
                  ),
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
                        // Message Button (Primary)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _startChat(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(
                              Icons.chat_bubble_rounded,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Message',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        if (post.ownerPhone != null &&
                            post.ownerPhone!.isNotEmpty) ...[
                          SizedBox(width: 12.w),
                          // Call Button (Secondary)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _makeCall(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primaryColor,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  side: BorderSide(
                                    color: primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                                elevation: 0,
                              ),
                              icon: Icon(
                                Icons.phone_in_talk_rounded,
                                color: primaryColor,
                              ),
                              label: Text(
                                'Call',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ).animate().slideY(
                  begin: 1.0,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOutCirc,
                ),
        );
      },
    );
  }
}
