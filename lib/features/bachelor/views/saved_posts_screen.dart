import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/utils/app_logger.dart';
import '../../landlord/controllers/post_controller.dart';
import '../../notifications/views/widgets/notification_bell_action.dart';
import 'room_detail_screen.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final postController = Get.find<PostController>();


    return Obx(() {
      final rolePrimaryColor = const Color(0xFF059669);

      final posts = postController.savedPosts;
      AppLogger.i('DEBUG: SavedPostsScreen built. allPosts=${postController.allPosts.length}, savedPostIds=${postController.savedPostIds.length}, savedPosts=${posts.length}', tag: 'SAVED_POSTS');

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: rolePrimaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          centerTitle: true,
          title: Text(
            'Saved Messes',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: Colors.white,
            ),
          ),
          actions: const [
            NotificationBellAction(),
          ],
        ),
        body: RefreshIndicator(
          color: rolePrimaryColor,
          onRefresh: () async {
            await postController.refreshPosts();
          },
          child: posts.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.8,
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.all(32.r),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(24.r),
                            decoration: BoxDecoration(
                              color: rolePrimaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite_border_rounded,
                              size: 56.r,
                              color: rolePrimaryColor,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No Saved Messes',
                            style: GoogleFonts.poppins(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Tap the heart icon on any mess card in your feed to save it here for quick access.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
            : ListView.builder(
              padding: EdgeInsets.all(16.r),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Dismissible(
                  key: Key(post.postId),
                  direction: DismissDirection.horizontal,
                  onDismissed: (direction) {
                    postController.toggleSavePost(post.postId);
                  },
                  background: _buildDismissBackground(isLeft: true),
                  secondaryBackground: _buildDismissBackground(isLeft: false),
                  child: GestureDetector(
                    onTap: () {
                      Get.to(
                        () => RoomDetailScreen(post: post),
                        transition: Transition.rightToLeft,
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                             borderRadius: BorderRadius.all(Radius.circular(20.r)),
                            color: Colors.white,
                          ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Top Section: Landlord Profile & Favorite Button
                          Row(
                            children: [
                              Expanded(
                                child: FutureBuilder<Map<String, dynamic>?>(
                                  initialData: postController
                                      .landlordProfilesCache[post.ownerUid],
                                  future:
                                      postController.landlordProfilesCache
                                          .containsKey(post.ownerUid)
                                      ? null
                                      : postController.getLandlordProfile(
                                          post.ownerUid,
                                        ),
                                  builder: (context, snapshot) {
                                    final profile = snapshot.data;
                                    final name =
                                        profile?['name']?.toString() ??
                                        'Landlord / Manager';
                                    final photoUrl = (profile?['profile_image'] ??
                                             profile?['photoUrl'])
                                         ?.toString();
                                     const isPaid = true; // 🆓 Free Launch: always verified
                                    final fullPhone =
                                        post.ownerPhone ??
                                        profile?['phone']?.toString() ??
                                        '017********';
                                    // 🆓 Free Launch: always show full phone
                                    final maskedPhone = fullPhone;

                                    return Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20.r,
                                          backgroundColor: rolePrimaryColor
                                              .withValues(alpha: 0.1),
                                          backgroundImage:
                                              (photoUrl != null &&
                                                  photoUrl.isNotEmpty)
                                              ? NetworkImage(photoUrl)
                                              : null,
                                          child:
                                              (photoUrl == null ||
                                                  photoUrl.isEmpty)
                                              ? Icon(
                                                  Icons.person,
                                                  size: 22.r,
                                                  color: rolePrimaryColor,
                                                )
                                              : null,
                                        ),
                                        SizedBox(width: 10.w),
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
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 14.sp,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppTheme.textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isPaid) ...[
                                                    SizedBox(width: 4.w),
                                                    Icon(Icons.verified_rounded, color: Colors.blue, size: 14.r),
                                                  ],
                                                ],
                                              ),
                                              Text(
                                                maskedPhone,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11.sp,
                                                  color: AppTheme.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              // Favorite Button
                              GestureDetector(
                                onTap: () =>
                                    postController.toggleSavePost(post.postId),
                                child: Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorColor.withValues(
                                      alpha: 0.08,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.favorite_rounded,
                                    color: AppTheme.errorColor,
                                    size: 22.r,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),

                          // Divider
                          Divider(
                            color: Colors.grey.shade100,
                            height: 1,
                            thickness: 1.5,
                          ),
                          SizedBox(height: 12.h),

                          // 2. Bottom Section: Image & Post Details
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image Section
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: post.images.isNotEmpty
                                    ? AppImageHelper.buildImage(
                                        post.images.first,
                                        width: 110.w,
                                        height: 110.h,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 110.w,
                                        height: 110.h,
                                        color: Colors.grey.shade100,
                                        child: Icon(
                                          Icons.home_work_rounded,
                                          color: Colors.grey.shade400,
                                          size: 40.r,
                                        ),
                                      ),
                              ),
                              SizedBox(width: 12.w),

                              // Details Section
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                        height: 1.3,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.location_on_rounded,
                                          size: 14.r,
                                          color: Colors.grey.shade500,
                                        ),
                                        SizedBox(width: 4.w),
                                        Expanded(
                                          child: Text(
                                            post.address,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 11.sp,
                                              color: AppTheme.textSecondary,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    Wrap(
                                      spacing: 6.w,
                                      runSpacing: 6.h,
                                      children: [
                                        _buildTag(
                                          Icons.person_rounded,
                                          post.bachelorType.capitalizeFirst ??
                                              post.bachelorType,
                                          rolePrimaryColor.withValues(
                                            alpha: 0.08,
                                          ),
                                          rolePrimaryColor,
                                        ),
                                        _buildTag(
                                          Icons.king_bed_rounded,
                                          '${post.displaySeats} Seats',
                                          rolePrimaryColor.withValues(
                                            alpha: 0.08,
                                          ),
                                          rolePrimaryColor,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Rent:',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'Tk.${post.rent.toInt()}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 17.sp,
                                            fontWeight: FontWeight.bold,
                                            color: rolePrimaryColor,
                                            height: 1.0,
                                          ),
                                        ),
                                        Text(
                                          ' / month',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ), // Close Container
                    SizedBox(height: 10.h),
                  ],
                ), // Close Column
              ), // Close GestureDetector
            ); // Close Dismissible
              },
            ),
        ),
      );
    });
  }

  Widget _buildTag(
    IconData icon,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.r, color: textColor),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissBackground({required bool isLeft}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppTheme.errorColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isLeft
            ? [
                Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 28.r,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Remove',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ]
            : [
                Text(
                  'Remove',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 28.r,
                ),
              ],
      ),
    );
  }
}
