import '../../../core/utils/app_logger.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mess_finder/core/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mess_finder/features/chat/controllers/chat_controller.dart';
import 'package:mess_finder/features/chat/views/chat_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/api_constants.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notifications/views/widgets/notification_bell_action.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repo.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final Color primaryColor = const Color(0xFF059669);
  late Future<List<BookingModel>> _bookingsFuture;
  final repo = BookingRepository();
  String _uid = '';

  @override
  void initState() {
    super.initState();
    final auth = Get.find<AuthController>();
    _uid = auth.currentUser.value?.uid ?? '';
    _loadBookings();
  }

  void _loadBookings() {
    if (_uid.isNotEmpty) {
      _bookingsFuture = repo.getBachelorBookingsFromApi(_uid);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loadBookings();
    });
    await _bookingsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
         icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Contacted Rooms',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [
          NotificationBellAction(),
        ],
      ),
      body: _uid.isEmpty
          ? Center(
              child: Text(
                'Please log in to view your contacted rooms.',
                style: GoogleFonts.poppins(
                    fontSize: 14.sp, color: AppTheme.textSecondary),
              ),
            )
          : FutureBuilder<List<BookingModel>>(
              future: _bookingsFuture,
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
                          'Failed to load contacted rooms.',
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
                    onRefresh: _refresh,
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
                              'No rooms contacted yet',
                              style: GoogleFonts.poppins(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Rooms you have contacted\nwill appear here.',
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

                return RefreshIndicator(
                  color: primaryColor,
                  onRefresh: _refresh,
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
                      child: Row(
                        children: [
                          Icon(Icons.contact_phone_rounded,
                              color: primaryColor, size: 22.r),
                          SizedBox(width: 10.w),
                          Text(
                            'You have contacted ${bookings.length} room${bookings.length == 1 ? '' : 's'}',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
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

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  Future<Map<String, dynamic>> _fetchPostInfo() async {
    try {
      final apiService = Get.isRegistered<ApiService>() ? Get.find<ApiService>() : Get.put(ApiService());
      
      // 1. Fetch Post Info from PostgreSQL backend
      final postRes = await apiService.dio.get(ApiConstants.postById(booking.postId));
      
      if (postRes.statusCode == 200 && postRes.data != null) {
        final postData = postRes.data;
        
        String ownerUid = postData['owner_uid']?.toString() ?? postData['ownerUid']?.toString() ?? '';
        String ownerName = 'Unknown Landlord';
        String? ownerPhoto;
        String ownerPhone = postData['owner_phone']?.toString() ?? postData['ownerPhone']?.toString() ?? '';
        
        // 2. Fetch Landlord Info from PostgreSQL backend
        if (ownerUid.isNotEmpty) {
          try {
            final userRes = await apiService.dio.get(ApiConstants.authUserById(ownerUid));
            if (userRes.statusCode == 200 && userRes.data != null) {
              final userData = userRes.data['user'] ?? userRes.data['data'] ?? userRes.data;
              ownerName = userData['name']?.toString() ?? 'Unknown Landlord';
              ownerPhoto = userData['profile_image']?.toString() ?? userData['photoUrl']?.toString();
              
              if (ownerPhone.isEmpty) {
                ownerPhone = userData['phone']?.toString() ?? '';
              }
            }
          } catch (e) {
            AppLogger.e('Error fetching landlord user info: $e');
          }
        }
        
        return {
          'postTitle': postData['title']?.toString() ?? 'Unknown Room',
          'postAddress': postData['address']?.toString() ?? '—',
          'postRent': double.tryParse(postData['rent']?.toString() ?? '0') ?? 0.0,
          'ownerPhone': ownerPhone,
          'ownerName': ownerName,
          'ownerPhotoUrl': ownerPhoto,
          'ownerUid': ownerUid,
        };
      }
    } catch (e) {
      AppLogger.e('Error fetching post info for booking: $e');
    }
    
    throw Exception('Not found');
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
    final b = booking;

    final primaryColor = const Color(0xFF059669);

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchPostInfo(),
      builder: (context, snapshot) {
        String postTitle = '...';
        String postAddress = '...';
        double postRent = 0;
        String ownerPhone = '';
        String ownerName = 'Loading...';
        String? ownerPhotoUrl;
        String ownerUid = '';

        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            final data = snapshot.data!;
            postTitle = data['postTitle'];
            postAddress = data['postAddress'];
            postRent = data['postRent'];
            ownerPhone = data['ownerPhone'];
            ownerName = data['ownerName'];
            ownerPhotoUrl = data['ownerPhotoUrl'];
            ownerUid = data['ownerUid'];
          } else {
            postTitle = 'Room not found';
            postAddress = '—';
            ownerName = 'Unknown';
          }
        }

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
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

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
                      backgroundImage: ownerPhotoUrl != null && ownerPhotoUrl.isNotEmpty
                          ? NetworkImage(ownerPhotoUrl)
                          : null,
                      child: ownerPhotoUrl == null || ownerPhotoUrl.isEmpty
                          ? Icon(Icons.person_rounded, size: 20.r, color: Colors.grey.shade500)
                          : null,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ownerName,
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
                    Text(
                      _timeAgo(b.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
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
                        postTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (postRent > 0)
                      Text(
                        'Tk.${postRent.toInt()}/mo',
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
                        postAddress,
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
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (ownerPhone.isEmpty) return;
                          final url = Uri.parse('tel:$ownerPhone');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.h),
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
                          if (ownerUid.isNotEmpty) {
                            final chatController = Get.find<ChatController>();
                            // Use a loading dialog if needed, but for now just navigate quickly
                            final roomId = await chatController.createOrGetChatRoom(
                              ownerUid,
                              ownerName,
                              ownerPhotoUrl,
                            );
                            Get.to(() => ChatScreen(
                              chatRoomId: roomId,
                              targetUserId: ownerUid,
                              targetUserName: ownerName,
                              targetUserPhoto: ownerPhotoUrl,
                            ));
                          } else {
                            Get.snackbar('Error', 'Landlord ID not found.');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.h),
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
      ),
    ),
  );
      },
    );
  }
}
