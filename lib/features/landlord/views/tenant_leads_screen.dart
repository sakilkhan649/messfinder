import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../notifications/views/widgets/notification_bell_action.dart';
import '../../bachelor/models/booking_model.dart';
import '../controllers/tenant_leads_controller.dart';
import '../models/post_model.dart';

class TenantLeadsScreen extends StatelessWidget {
  final PostModel? post;

  const TenantLeadsScreen({super.key, this.post});

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = Color(0xFF059669);
    const darkEmerald = Color(0xFF064E3B);

    // Initialize GetX Controller
    final controller = Get.find<TenantLeadsController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: darkEmerald,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20.r),
          onPressed: () => Get.back(),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          post != null ? post!.title : 'Bachelor booking requests',
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
      body: StreamBuilder<List<BookingModel>>(
        stream: controller.getLeadsStream(post),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryEmerald),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48.r,
                    color: Colors.redAccent,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Failed to load leads.\nPlease check your connection.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final allLeads = snapshot.data ?? [];



          return Column(
            children: [
              // ── Top Summary Card ──────────────────────────────────────
              Container(
                margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      darkEmerald.withValues(alpha: 0.08),
                      primaryEmerald.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: primaryEmerald.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_alt_rounded,
                      color: primaryEmerald,
                      size: 22.r,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'Total ${allLeads.length} Request${allLeads.length == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Search Bar ────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                child: TextField(
                  textAlignVertical: TextAlignVertical.center,
                  onChanged: controller.updateSearch,
                  style: GoogleFonts.poppins(fontSize: 13.sp),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search by Name or Phone...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: primaryEmerald,
                      size: 20.r,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),

              // ── Leads List ───────────────────────────────────────────
              Expanded(
                child: Obx(() {
                  final filteredLeads = controller.filterLeads(
                    allLeads,
                    1, // Force it to look at 'approved' leads since all leads are now instantly approved
                    controller.searchQuery.value,
                  );

                  if (filteredLeads.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 56.r,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'No leads found',
                            style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'When bachelors view your contact,\nthey will appear here.',
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

                  return RefreshIndicator(
                    color: primaryEmerald,
                    onRefresh: () async {
                      // Stream builder auto-updates, but this provides pull-to-refresh UX delay
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                    itemCount: filteredLeads.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 14.h),
                    itemBuilder: (context, index) {
                      final lead = filteredLeads[index];
                      return Dismissible(
                        key: Key(lead.bookingId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          alignment: Alignment.centerRight,
                          child: Icon(
                            Icons.delete_sweep_rounded,
                            color: Colors.white,
                            size: 28.r,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await Get.defaultDialog<bool>(
                            title: 'Delete Request',
                            titleStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                            ),
                            middleText: 'Are you sure you want to permanently delete this lead?',
                            middleTextStyle: GoogleFonts.poppins(
                              fontSize: 14.sp,
                            ),
                            textCancel: 'Cancel',
                            textConfirm: 'Delete',
                            confirmTextColor: Colors.white,
                            buttonColor: const Color(0xFFEF4444),
                            cancelTextColor: const Color(0xFF6B7280),
                            onConfirm: () => Get.back(result: true),
                            onCancel: () => Get.back(result: false),
                            radius: 12.r,
                          );
                        },
                        onDismissed: (direction) {
                          controller.deleteLead(lead.bookingId);
                        },
                        child: _LeadCard(
                          booking: lead,
                          controller: controller,
                        ),
                      );
                    },
                  ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Lead Card Widget with Clean Alignment & Easy Text ─────────────────
class _LeadCard extends StatelessWidget {
  final BookingModel booking;
  final TenantLeadsController controller;

  const _LeadCard({required this.booking, required this.controller});

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
    const primaryEmerald = Color(0xFF059669);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: FutureBuilder<Map<String, String>>(
        future: controller.getBachelorInfo(booking),
        builder: (context, snapshot) {
          final userInfo =
              snapshot.data ?? {'name': 'Loading...', 'phone': '—'};
          final name = userInfo['name']!;
          final phone = userInfo['phone']!;
          final rawPhone = (phone.isNotEmpty && phone != '—' && phone != '')
              ? phone
              : (booking.senderNumber.isNotEmpty
                  ? booking.senderNumber
                  : 'Not provided');
          final displayPhone = rawPhone;
          final initials = name.isNotEmpty && name != 'Loading...'
              ? name[0].toUpperCase()
              : '?';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Avatar + Name + Status Badge ──────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 22.r,
                    backgroundColor: const Color(0xFFECFDF5),
                    child: Text(
                      initials,
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: primaryEmerald,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _timeAgo(booking.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14.r, color: const Color(0xFF047857)),
                        SizedBox(width: 4.w),
                        Text(
                          'Viewed Contact',
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),
              Divider(height: 1, color: Colors.grey.shade200),
              SizedBox(height: 12.h),

              // ── Simple Info Row ────────────
              _buildInfoRow(
                icon: Icons.phone_rounded,
                label: 'Phone Number',
                value: displayPhone,
                color: primaryEmerald,
                onCopy: () => controller.copyPhoneNumber(rawPhone),
              ),

              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16.r,
                      color: primaryEmerald,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'This tenant has viewed your phone number.',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF064E3B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onCopy,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16.r, color: color),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            color: AppTheme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onCopy != null)
          GestureDetector(
            onTap: onCopy,
            child: Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: Icon(Icons.copy_rounded, size: 16.r, color: color),
            ),
          ),
      ],
    );
  }
}
