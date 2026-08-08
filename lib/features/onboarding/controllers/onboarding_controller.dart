import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/middlewares/auth_middleware.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  final List<OnboardingContent> pages = [
    OnboardingContent(
      title: 'Find Your Perfect Mess',
      description: 'Search for rooms or bachelors easily using our interactive map.',
      imagePath: 'assets/images/onboarding_search.png',
    ),
    OnboardingContent(
      title: 'Direct Chat',
      description: 'Connect instantly with landlords or bachelors through real-time chat.',
      imagePath: 'assets/images/onboarding_chat.png',
    ),
    OnboardingContent(
      title: 'Manage Bookings',
      description: 'Send booking requests and manage your tenant leads effortlessly.',
      imagePath: 'assets/images/onboarding_booking.png',
    ),
  ];

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void nextPage() {
    if (currentPage.value < pages.length - 1) {
      pageController.animateToPage(
        currentPage.value + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skipOnboarding() {
    completeOnboarding();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    
    // Check auth and route appropriately
    AuthMiddleware.checkAuthAndNavigate();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final String imagePath;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}
