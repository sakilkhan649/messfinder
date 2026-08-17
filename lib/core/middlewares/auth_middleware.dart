import 'package:get/get.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/views/login_screen.dart';

class AuthMiddleware {
  /// Checks if the user is authenticated and has a valid session.
  /// Navigates to the appropriate home screen if authenticated,
  /// otherwise navigates to the role selection screen.
  static Future<void> checkAuthAndNavigate() async {
    final authController = Get.find<AuthController>();
    
    try {
      await authController.checkAuthStatus();
    } catch (e) {
      Get.off(() => const LoginScreen(), transition: Transition.fadeIn);
    }
  }
}
