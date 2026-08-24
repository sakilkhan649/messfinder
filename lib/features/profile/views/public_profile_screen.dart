import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../landlord/models/post_model.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../chat/views/chat_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../bachelor/views/bachelor_home_screen.dart'; // To access BachelorPostCard
import '../../landlord/controllers/post_controller.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  String name = 'Loading...';
  String? profilePic;
  bool isPaid = true; // 🆓 Free Launch: always verified
  bool isLoaded = false;
  List<PostModel> userPosts = [];
  bool isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    _loadProfileAndPosts();
  }

  Future<void> _loadProfileAndPosts() async {
    try {
      final postCtrl = Get.find<PostController>();
      final data = await postCtrl.getLandlordProfile(widget.userId);
      if (data != null) {
        name = data['name'] ?? 'Landlord';
        profilePic = data['profile_image'] ?? data['photoUrl'];
        isPaid = true; // 🆓 Free Launch: always verified
      } else {
        name = 'Landlord';
      }
    } catch (e) {
      debugPrint('Error loading public profile: $e');
      name = 'Landlord';
    }

    try {
      // Fetch user's posts via REST API
      final postsRes = await ApiService().dio.get(
        '/posts',
        queryParameters: {'ownerUid': widget.userId},
      );

      if (postsRes.statusCode == 200 && postsRes.data != null) {
        final List list = postsRes.data is List ? postsRes.data : [];
        userPosts = list
            .map((item) => PostModel.fromMap(
                  Map<String, dynamic>.from(item),
                  (item['id'] ?? item['post_id'] ?? '').toString(),
                ))
            .toList();

        // Sort locally by createdAt desc
        userPosts.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
      }
    } catch (e) {
      debugPrint('Error loading posts: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoaded = true;
          isLoadingPosts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF059669);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        surfaceTintColor: primaryColor,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: !isLoaded
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _loadProfileAndPosts,
              color: primaryColor,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                SliverToBoxAdapter(
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        height: 100.h,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(32.r),
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(top: 20.h, left: 24.w, right: 24.w),
                        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.08),
                              blurRadius: 24.r,
                              offset: Offset(0, 8.h),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4.w),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10.r,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 45.r,
                                backgroundColor: primaryColor.withValues(alpha: 0.1),
                                backgroundImage: profilePic != null && profilePic!.isNotEmpty
                                    ? NetworkImage(profilePic!)
                                    : null,
                                child: profilePic == null || profilePic!.isEmpty
                                    ? Icon(Icons.person_rounded, size: 40.r, color: primaryColor)
                                    : null,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (isPaid) ...[
                                  SizedBox(width: 6.w),
                                  Icon(Icons.verified_rounded, color: Colors.blue, size: 22.r),
                                ],
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              isPaid ? 'Verified Landlord' : 'Landlord',
                              style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            // Message Button
                            if (Get.find<AuthController>().currentUser.value?.uid != widget.userId)
                              ElevatedButton.icon(
                                onPressed: () async {
                                  if (!Get.isRegistered<ChatController>()) {
                                    Get.put(ChatController());
                                  }
                                  final chatCtrl = Get.find<ChatController>();
                                  final chatId = await chatCtrl.createOrGetChatRoom(
                                      widget.userId, name, profilePic);
                                  Get.to(() => ChatScreen(
                                      chatRoomId: chatId,
                                      targetUserId: widget.userId,
                                      targetUserName: name,
                                      targetUserPhoto: profilePic));
                                },
                                icon: Icon(Icons.chat_bubble_outline_rounded, size: 18.r, color: Colors.white),
                                label: Text(
                                  'Message',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.r),
                                  ),
                                ),
                              ),
                            if (!isLoadingPosts) ...[
                              SizedBox(height: 20.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.home_work_rounded, size: 16.r, color: primaryColor),
                                        SizedBox(width: 8.w),
                                          Text(
                                            '${userPosts.length} Active Listing${userPosts.length == 1 ? '' : 's'}',
                                            style: GoogleFonts.poppins(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 16.h),
                    child: Row(
                      children: [
                        Text(
                          'Available Properties',
                          style: GoogleFonts.poppins(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (!isLoadingPosts && userPosts.isNotEmpty)
                          Text(
                          '${userPosts.length} Result${userPosts.length == 1 ? '' : 's'}',
                          style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                isLoadingPosts
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32.r),
                          child: Center(child: CircularProgressIndicator(color: primaryColor)),
                        ),
                      )
                    : userPosts.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(32.r),
                              child: Center(
                                child: Text(
                                  'No active listings available.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return BachelorPostCard(post: userPosts[index]);
                              },
                              childCount: userPosts.length,
                            ),
                          ),
                SliverToBoxAdapter(child: SizedBox(height: 40.h)),
              ],
            ),
            ),
    );
  }
}
