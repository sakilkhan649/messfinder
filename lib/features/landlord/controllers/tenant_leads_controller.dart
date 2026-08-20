import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../bachelor/models/booking_model.dart';
import '../../bachelor/repositories/booking_repo.dart';
import '../models/post_model.dart';

class TenantLeadsController extends GetxController {
  final BookingRepository _bookingRepo = BookingRepository();
  final AuthController _authController = Get.find<AuthController>();

  final RxInt selectedTabIndex = 0.obs; // 0 = Pending, 1 = Approved, 2 = Rejected
  final RxString searchQuery = ''.obs;

  final RxList<BookingModel> leads = <BookingModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;

  void setTab(int index) {
    selectedTabIndex.value = index;
  }

  void updateSearch(String query) {
    searchQuery.value = query;
  }

  Future<void> fetchLeads(PostModel? post) async {
    isLoading.value = true;
    hasError.value = false;
    try {
      List<BookingModel> fetchedLeads;
      if (post != null) {
        fetchedLeads = await _bookingRepo.getPostLeadsFromApi(post.postId);
      } else {
        final landlordUid = _authController.currentUser.value?.uid ?? '';
        fetchedLeads = await _bookingRepo.getLandlordLeadsFromApi(landlordUid);
      }
      
      // Sort by newest first
      fetchedLeads.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      leads.value = fetchedLeads;
    } catch (e) {
      AppLogger.e('Error fetching leads in controller: $e', e, null, 'LEADS_CTRL');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  void copyPhoneNumber(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    Get.snackbar(
      'Copied',
      'Phone number copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  List<BookingModel> filterLeads(
    List<BookingModel> leadsList,
    int tabIndex,
    String query,
  ) {
    // 1. Filter by status
    final statusFiltered = leadsList.where((b) {
      final s = b.paymentStatus.trim().toLowerCase();
      if (tabIndex == 0) return s == 'pending';
      if (tabIndex == 1) return s == 'approved';
      return s == 'rejected';
    }).toList();

    // 2. Filter by search query (Name or Phone number)
    if (query.trim().isEmpty) {
      return statusFiltered;
    }
    final q = query.trim().toLowerCase();
    return statusFiltered.where((b) {
      final isApproved = b.isUnlocked || b.paymentStatus.trim().toLowerCase() == 'approved';
      final bName = b.bachelorName?.toLowerCase() ?? '';
      final bPhone = b.bachelorPhone?.toLowerCase() ?? '';

      final matchName = bName.contains(q);
      final matchPhone = isApproved && bPhone.contains(q);

      return matchName || matchPhone;
    }).toList();
  }

  Future<void> deleteLead(String bookingId) async {
    try {
      await _bookingRepo.deleteBookingApi(bookingId);
      leads.removeWhere((element) => element.bookingId == bookingId);
      Get.snackbar(
        'Deleted',
        'Request has been removed successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete request: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: const Color(0xFFFFFFFF),
      );
    }
  }

  Future<void> approveLead(String bookingId) async {
    try {
      await _bookingRepo.approveBookingApi(bookingId);
      final index = leads.indexWhere((element) => element.bookingId == bookingId);
      if (index != -1) {
        final current = leads[index];
        leads[index] = current.copyWith(
          paymentStatus: 'approved',
          isUnlocked: true,
        );
      }
      Get.snackbar(
        'Approved',
        'Request approved successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF059669),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to approve request: $e');
    }
  }

  Future<void> rejectLead(String bookingId) async {
    try {
      await _bookingRepo.rejectBookingApi(bookingId);
      final index = leads.indexWhere((element) => element.bookingId == bookingId);
      if (index != -1) {
        final current = leads[index];
        leads[index] = current.copyWith(
          paymentStatus: 'rejected',
          isUnlocked: false,
        );
      }
      Get.snackbar(
        'Rejected',
        'Request rejected.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to reject request: $e');
    }
  }
}
