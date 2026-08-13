import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/views/login_screen.dart';

class AuthMiddleware {
  /// Checks if the user is authenticated and has a valid session.
  /// Navigates to the appropriate home screen if authenticated,
  /// otherwise navigates to the role selection screen.
  static Future<void> checkAuthAndNavigate() async {
    // Wait for the Firebase Auth state to be fully initialized
    final user = await FirebaseAuth.instance.authStateChanges().first;

    if (user != null) {
      final authController = Get.find<AuthController>();
      await authController.fetchUserData(user.uid);

      if (authController.currentUser.value != null) {
        authController.handleNavigation(authController.currentUser.value!);
        return;
      }
    }

    Get.off(() => const LoginScreen(), transition: Transition.fadeIn);
  }
}
