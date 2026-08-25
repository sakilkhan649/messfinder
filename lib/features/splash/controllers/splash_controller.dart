import 'package:get/get.dart';
import '../../../core/middlewares/auth_middleware.dart';
import '../../../core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import '../../onboarding/views/onboarding_screen.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToNext();
  }

  @override
  void onReady() {
    super.onReady();
    // Initialize NotificationService after the UI is ready
    NotificationService().initialize();
  }

  void _navigateToNext() async {
    // Immediately check if launched from a CallKit incoming call
    try {
      final activeCalls = await FlutterCallkitIncoming.activeCalls();
      if (activeCalls.isNotEmpty) {
        // App was launched by accepting a call. 
        // Do NOT wait 2.5s. The NotificationService will push the CallScreen instantly.
        // We pause the splash navigation so it doesn't overwrite the CallScreen.
        return;
      }
    } catch (e) {
      // ignore
    }

    // Normal splash delay
    await Future.delayed(const Duration(milliseconds: 2500));
    
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!hasSeenOnboarding) {
      Get.off(() => const OnboardingScreen(), transition: Transition.fadeIn);
    } else {
      await AuthMiddleware.checkAuthAndNavigate();
    }
  }
}
