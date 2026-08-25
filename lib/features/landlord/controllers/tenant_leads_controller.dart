import 'dart:async';
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

  final RxString searchQuery = ''.obs;

  final RxList<BookingModel> leads = <BookingModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;

  StreamSubscription? _leadsSubscription;

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
    String query,
  ) {
    // Filter by search query (Name or Phone number)
    if (query.trim().isEmpty) {
      return leadsList;
    }
    final q = query.trim().toLowerCase();
    return leadsList.where((b) {
      final bName = b.bachelorName?.toLowerCase() ?? '';
      final bPhone = b.bachelorPhone?.toLowerCase() ?? '';

      final matchName = bName.contains(q);
      final matchPhone = bPhone.contains(q);

      return matchName || matchPhone;
    }).toList();
  }

  Future<void> deleteLead(String bookingId) async {
    try {
      await _bookingRepo.deleteBooking(bookingId);
      // Since we are using a stream, local deletion isn't strictly necessary 
      // as the stream will update, but we can do it for instant UI feedback.
      leads.removeWhere((element) => element.bookingId == bookingId);
      Get.snackbar(
        'Deleted',
        'Contact request has been removed.',
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

  @override
  void onClose() {
    _leadsSubscription?.cancel();
    super.onClose();
  }
}

