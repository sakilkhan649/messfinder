import 'package:get/get.dart';
import '../../../core/middlewares/auth_middleware.dart';
import '../../../core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
