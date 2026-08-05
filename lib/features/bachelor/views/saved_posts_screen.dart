import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_helper.dart';
import '../../landlord/controllers/post_controller.dart';
import 'room_detail_screen.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final postController = Get.put(PostController());
    const primaryBlue = Color(0xFF0EA5E9);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        title: Text(
          'Saved Messes',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Obx(() {
        final posts = postController.savedPosts;

        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.favorite_border_rounded,
                        size: 56.r, color: primaryBlue),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No Saved Messes',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Tap the heart icon on any mess card in your feed to save it here for quick access.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
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
                child: Container(
                  margin: EdgeInsets.only(bottom: 14.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10.r,
                        offset: Offset(0, 3.h),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(16.r),
                        ),
                        child: post.images.isNotEmpty
                            ? AppImageHelper.buildImage(
                                post.images.first,
                                width: 100.w,
                                height: 100.h,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 100.w,
                                height: 100.h,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.home_work_rounded),
                              ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                post.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                '৳${post.rent.toInt()} / mo',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 14.w),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: AppTheme.errorColor,
                          size: 24.r,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildDismissBackground({required bool isLeft}) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
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
                Icon(Icons.delete_outline_rounded,
                    color: Colors.white, size: 28.r),
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
                Icon(Icons.delete_outline_rounded,
                    color: Colors.white, size: 28.r),
              ],
      ),
    );
  }
}
