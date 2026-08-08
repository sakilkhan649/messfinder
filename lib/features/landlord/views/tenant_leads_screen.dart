import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
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

          // Calculate statistics
          final pendingCount = allLeads
              .where((b) => b.paymentStatus.trim().toLowerCase() == 'pending')
              .length;
          final approvedCount = allLeads
              .where((b) => b.paymentStatus.trim().toLowerCase() == 'approved')
              .length;
          final rejectedCount = allLeads
              .where((b) => b.paymentStatus.trim().toLowerCase() == 'rejected')
              .length;

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
                  onChanged: controller.updateSearch,
                  style: GoogleFonts.poppins(fontSize: 13.sp),
                  decoration: InputDecoration(
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

              // ── Simple Tab Selector (Pending / Approved / Rejected) ──
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: Obx(() {
                  final activeTab = controller.selectedTabIndex.value;
                  return Row(
                    children: [
                      Expanded(
                        child: _buildTabChip(
                          title: 'Pending ($pendingCount)',
                          isSelected: activeTab == 0,
                          selectedColor: const Color(0xFFF59E0B),
                          onTap: () => controller.setTab(0),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _buildTabChip(
                          title: 'Approved ($approvedCount)',
                          isSelected: activeTab == 1,
                          selectedColor: primaryEmerald,
                          onTap: () => controller.setTab(1),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _buildTabChip(
                          title: 'Rejected ($rejectedCount)',
                          isSelected: activeTab == 2,
                          selectedColor: const Color(0xFFEF4444),
                          onTap: () => controller.setTab(2),
                        ),
                      ),
                    ],
                  );
                }),
              ),

              // ── Leads List ───────────────────────────────────────────
              Expanded(
                child: Obx(() {
                  final filteredLeads = controller.filterLeads(
                    allLeads,
                    controller.selectedTabIndex.value,
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
                            'No requests found',
                            style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'When bachelors request your room,\nthey will appear here.',
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
                            middleText: 'Are you sure you want to permanently delete this request?',
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

  Widget _buildTabChip({
    required String title,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.25),
                    blurRadius: 6.r,
                    offset: Offset(0, 2.h),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
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

  ({Color bg, Color text, String label, IconData icon}) _statusInfo(
    String status,
  ) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return (
          bg: const Color(0xFFD1FAE5),
          text: const Color(0xFF047857),
          label: 'Approved',
          icon: Icons.check_circle_rounded,
        );
      case 'rejected':
        return (
          bg: const Color(0xFFFEE2E2),
          text: const Color(0xFFB91C1C),
          label: 'Rejected',
          icon: Icons.cancel_rounded,
        );
      default:
        return (
          bg: const Color(0xFFFEF3C7),
          text: const Color(0xFFB45309),
          label: 'Pending Review',
          icon: Icons.pending_actions_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = Color(0xFF059669);
    final st = _statusInfo(booking.paymentStatus);

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
          final isApproved = booking.isUnlocked ||
              booking.paymentStatus.trim().toLowerCase() == 'approved';
          final isRejected =
              booking.paymentStatus.trim().toLowerCase() == 'rejected';
          final name = userInfo['name']!;
          final phone = userInfo['phone']!;
          final rawPhone = (phone.isNotEmpty && phone != '—' && phone != '')
              ? phone
              : (booking.senderNumber.isNotEmpty
                  ? booking.senderNumber
                  : 'Not provided');
          final displayPhone = isApproved
              ? rawPhone
              : (isRejected
                  ? 'Locked (Rejected by Admin) 🔒'
                  : 'Locked until Admin Approval 🔒');
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
                      color: st.bg,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(st.icon, size: 14.r, color: st.text),
                        SizedBox(width: 4.w),
                        Text(
                          st.label,
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: st.text,
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

              // ── Simple Info Row (Phone locked until approved for security) ────────────
              _buildInfoRow(
                icon: isApproved
                    ? Icons.phone_rounded
                    : Icons.lock_outline_rounded,
                label: 'Phone Number',
                value: displayPhone,
                color: isApproved
                    ? primaryEmerald
                    : (isRejected
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF59E0B)),
                onCopy: isApproved
                    ? () => controller.copyPhoneNumber(rawPhone)
                    : null,
              ),

              // ── Action Buttons for Pending Requests ───────────────────────
              if (booking.paymentStatus.trim().toLowerCase() == 'pending') ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => controller.rejectLead(booking.bookingId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEE2E2),
                          foregroundColor: const Color(0xFFB91C1C),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          'Reject',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => controller.approveLead(booking.bookingId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryEmerald,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          'Approve',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // ── Status / Unlocked Note ───────────────────────────────
              if (booking.isUnlocked ||
                  booking.paymentStatus.trim().toLowerCase() == 'approved') ...[
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
                        Icons.check_circle_rounded,
                        size: 16.r,
                        color: primaryEmerald,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Approved — you can call or contact this tenant',
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
