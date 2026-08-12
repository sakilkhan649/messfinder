import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import '../../../core/utils/location_data.dart';
import '../../landlord/controllers/post_controller.dart';
import '../../landlord/models/post_model.dart';
import '../../notifications/views/widgets/notification_bell_action.dart';
import 'room_detail_screen.dart';
import 'widgets/facebook_image_grid.dart';

class BachelorHomeScreen extends StatelessWidget {
  final UserModel user;

  const BachelorHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final postController = Get.find<PostController>();
    final Color primaryColor = const Color(0xFF059669); // Deep Indigo
    final Color accentColor = const Color(0xFFF59E0B); // Warm Amber Gold

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: () async {
          await postController.refreshPosts();
        },
        child: CustomScrollView(
          controller: postController.feedScrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── AppBar & Filters Section ───────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: primaryColor,
              elevation: 0,
              surfaceTintColor: primaryColor,
              automaticallyImplyLeading: false,
              titleSpacing: 16.w,
              title: Text(
                'Welcome to MessFinder',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              actions: const [NotificationBellAction()],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(132.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(50.r),
                        ),
                        child: TextField(
                          textAlignVertical: TextAlignVertical.center,
                          onChanged: (val) =>
                              postController.searchQuery.value = val,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            color: Colors.white,
                          ),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: Colors.transparent,
                            hintText: 'Search rooms, areas...',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              color: Colors.white70,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: Colors.white70,
                              size: 20.r,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 12.h,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildBudgetFilterButton(
                            context,
                            postController,
                            primaryColor,
                            accentColor,
                          ),
                          SizedBox(width: 8.w),
                          _buildLocationFilterButton(
                            context,
                            postController,
                            primaryColor,
                            accentColor,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Obx(() {
                                return Row(
                                  children: [
                                    _buildFilterChip(
                                      postController,
                                      'all',
                                      'All',
                                      primaryColor,
                                      accentColor,
                                    ),
                                    SizedBox(width: 8.w),
                                    _buildFilterChip(
                                      postController,
                                      'male',
                                      'Male Only',
                                      primaryColor,
                                      accentColor,
                                    ),
                                    SizedBox(width: 8.w),
                                    _buildFilterChip(
                                      postController,
                                      'female',
                                      'Female Only',
                                      primaryColor,
                                      accentColor,
                                    ),
                                    SizedBox(width: 8.w),
                                    _buildFilterChip(
                                      postController,
                                      'both',
                                      'Any',
                                      primaryColor,
                                      accentColor,
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Posts List ───────────────────────────────────────────────────────
            Obx(() {
              if (postController.isLoading.value) {
                return SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                );
              }

              final posts = postController.filteredPosts;

              if (posts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64.r,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No rooms found',
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Try adjusting your search or filters.',
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

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _BachelorPostCard(post: posts[index])
                      .animate()
                      .fade(duration: 400.ms)
                      .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOutQuad,
                        delay: (index * 50).ms,
                      );
                }, childCount: posts.length),
              );
            }),

            SliverToBoxAdapter(
              child: Obx(() {
                if (postController.isFetchingMore.value) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  );
                } else if (!postController.hasMorePosts.value && postController.allPosts.isNotEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Center(
                      child: Text(
                        'No more rooms to show',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }
                return SizedBox(height: 24.h);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    PostController controller,
    String value,
    String label,
    Color primaryColor,
    Color accentColor,
  ) {
    final isSelected = controller.selectedGenderFilter.value == value;

    return GestureDetector(
      onTap: () => controller.selectedGenderFilter.value = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.shade200,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 3.h),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetFilterButton(
    BuildContext context,
    PostController controller,
    Color primaryColor,
    Color accentColor,
  ) {
    return Obx(() {
      final isFiltered = controller.selectedBudgetFilter.value > 0;
      return GestureDetector(
        onTap: () => _showBudgetBottomSheet(
          context,
          controller,
          primaryColor,
          accentColor,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: isFiltered ? accentColor : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Icon(
            Icons.tune_rounded,
            size: 22.r,
            color: isFiltered ? Colors.white : primaryColor,
          ),
        ),
      );
    });
  }

  Widget _buildLocationFilterButton(
    BuildContext context,
    PostController controller,
    Color primaryColor,
    Color accentColor,
  ) {
    return Obx(() {
      final isFiltered = controller.selectedDivisionFilter.value != 'All';
      return InkWell(
        onTap: () => _showLocationFilterSheet(context, controller, primaryColor),
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isFiltered ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isFiltered ? primaryColor : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 16.r,
                color: isFiltered ? Colors.white : Colors.grey.shade700,
              ),
              SizedBox(width: 4.w),
              Text(
                isFiltered ? controller.selectedDistrictFilter.value : 'Location',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: isFiltered ? FontWeight.bold : FontWeight.w500,
                  color: isFiltered ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showLocationFilterSheet(
      BuildContext context, PostController controller, Color primaryColor) {
    String tempDiv = controller.selectedDivisionFilter.value;
    String tempDist = controller.selectedDistrictFilter.value;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter by Location',
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Division',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  DropdownButtonFormField<String>(
                    value: tempDiv == 'All' ? null : tempDiv,
                    hint: Text('Select Division', style: GoogleFonts.poppins(fontSize: 14.sp)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    items: ['All', ...LocationData.divisions].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value == 'All' ? null : value,
                        child: Text(value, style: GoogleFonts.poppins(fontSize: 14.sp)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        tempDiv = newValue ?? 'All';
                        if (tempDiv == 'All') {
                          tempDist = 'All';
                        } else {
                          tempDist = LocationData.getDistricts(tempDiv).first;
                        }
                      });
                    },
                  ),
                  SizedBox(height: 16.h),
                  if (tempDiv != 'All') ...[
                    Text(
                      'District',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    DropdownButtonFormField<String>(
                      value: tempDist == 'All' ? null : tempDist,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      items: ['All', ...LocationData.getDistricts(tempDiv)].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value == 'All' ? null : value,
                          child: Text(value, style: GoogleFonts.poppins(fontSize: 14.sp)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          tempDist = newValue ?? 'All';
                        });
                      },
                    ),
                    SizedBox(height: 24.h),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        controller.updateLocationFilter(tempDiv, tempDist);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Apply Filter',
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBudgetBottomSheet(
    BuildContext context,
    PostController controller,
    Color primaryColor,
    Color accentColor,
  ) {
    final List<Map<String, dynamic>> budgetOptions = [
      {'label': 'All Budgets', 'value': 0},
      {'label': 'Under Tk.4,000', 'value': 4000},
      {'label': 'Under Tk.5,000', 'value': 5000},
      {'label': 'Under Tk.6,000', 'value': 6000},
      {'label': 'Under Tk.7,000', 'value': 7000},
      {'label': 'Under Tk.8,000', 'value': 8000},
      {'label': 'Under Tk.10,000', 'value': 10000},
    ];

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Filter by Budget',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            Obx(() {
              return Column(
                children: budgetOptions.map((opt) {
                  final int val = opt['value'];
                  final String label = opt['label'];
                  final bool isSelected =
                      controller.selectedBudgetFilter.value == val;
                  return GestureDetector(
                    onTap: () {
                      controller.selectedBudgetFilter.value = val;
                      Get.back();
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor.withValues(alpha: 0.3)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected
                                ? primaryColor
                                : Colors.grey.shade400,
                            size: 20.r,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            label,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? primaryColor
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _BachelorPostCard extends StatefulWidget {
  final PostModel post;

  const _BachelorPostCard({required this.post});

  @override
  State<_BachelorPostCard> createState() => _BachelorPostCardState();
}

class _BachelorPostCardState extends State<_BachelorPostCard> {
  String name = 'Loading...';
  String? profilePic;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final postCtrl = Get.find<PostController>();
    final data = await postCtrl.getLandlordProfile(widget.post.ownerUid);
    if (mounted && data != null) {
      setState(() {
        name = data['name'] ?? 'Unknown User';
        profilePic = data['photoUrl'];
        isLoaded = true;
      });
    } else if (mounted) {
      setState(() {
        name = 'Unknown User';
        isLoaded = true;
      });
    }
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return 'Just now';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final Color primaryColor = const Color(0xFF059669); // Deep Indigo
    final Color accentColor = const Color(0xFFF59E0B); // Warm Amber Gold

    return GestureDetector(
      onTap: () => Get.to(
        () => RoomDetailScreen(post: post),
        transition: Transition.cupertino,
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Facebook Style Header (Landlord Profile) ──────────────────
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20.r,
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                        backgroundImage:
                            profilePic != null && profilePic!.isNotEmpty
                            ? NetworkImage(profilePic!)
                            : null,
                        child: profilePic == null || profilePic!.isEmpty
                            ? Icon(Icons.person_rounded, color: primaryColor)
                            : null,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _timeAgo(post.createdAt),
                              style: GoogleFonts.poppins(
                                fontSize: 11.sp,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── 2. Post Text Content ──────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: GoogleFonts.poppins(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16.r,
                            color: accentColor,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              post.address,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5.sp,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Tags Container
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          // Bachelor Type Tag
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 5.h,
                            ),
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
                                      post.bachelorType.toLowerCase() == 'male'
                                      ? Colors.blue.shade700
                                      : post.bachelorType.toLowerCase() ==
                                            'female'
                                      ? Colors.pink.shade700
                                      : Colors.purple.shade700,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  post.bachelorType.toLowerCase() == 'male'
                                      ? 'Male Only'
                                      : post.bachelorType.toLowerCase() ==
                                            'female'
                                      ? 'Female Only'
                                      : 'Any Bachelor',
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

                          // Preferred Tenant Tag
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 5.h,
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
                                  Icons.badge_rounded,
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

                          // Facilities
                          ...post.facilities.take(3).map((facility) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                facility,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                ),

                // ── 3. Post Image ──────────────────────────────────────────────────
                Stack(
                  children: [
                    SizedBox(
                      height: 200.h,
                      width: double.infinity,
                      child: post.images.isNotEmpty
                          ? FacebookImageGrid(images: post.images, borderRadius: 0)
                          : Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.home_work_rounded,
                                size: 48.r,
                                color: Colors.grey.shade400,
                              ),
                            ),
                    ),
                    Positioned(
                      top: 12.h,
                      left: 12.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          'Tk.${post.rent.toInt()} / mo',
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12.h,
                      right: 12.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '${post.seatCount} Seat${post.seatCount > 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── 4. Footer Actions ──────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Row(
                    children: [
                      Obx(() {
                        final postCtrl = Get.find<PostController>();
                        final isFav = postCtrl.isSaved(post.postId);
                        return IconButton(
                          onPressed: () => postCtrl.toggleSavePost(post.postId),
                          icon: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFav
                                ? const Color(0xFFEF4444)
                                : Colors.grey.shade400,
                            size: 28.r,
                          ),
                        );
                      }),
                      SizedBox(width: 8.w),
                      IconButton(
                        onPressed: () {
                          final shareText = 'Check out this room for rent!\n\n'
                              '${post.title}\n'
                              'Rent: Tk.${post.rent.toInt()}/month\n'
                              'Location: ${post.address}\n\n'
                              'Shared via Mess Finder App';
                          SharePlus.instance.share(ShareParams(text: shareText));
                        },
                        icon: Icon(
                          Icons.share_rounded,
                          color: Colors.grey.shade400,
                          size: 26.r,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => Get.to(
                          () => RoomDetailScreen(post: post),
                          transition: Transition.cupertino,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                          foregroundColor: primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 10.h,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Details',
                              style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(Icons.arrow_forward_rounded, size: 16.r),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
        ],
      ),
    );
  }
}
