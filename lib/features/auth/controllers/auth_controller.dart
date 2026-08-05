import 'package:get/get.dart';
import '../../../core/network/api_checker.dart';
import '../../../core/utils/app_constants.dart';
import '../../admin/views/admin_dashboard_screen.dart';
import '../../home/views/user_home_screen.dart';
import '../../payment/repositories/payment_repo.dart';
import '../models/user_model.dart';
import '../repositories/auth_repo.dart';
import '../views/login_screen.dart';
import '../views/role_selection_screen.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();
  final PaymentRepository _paymentRepo = PaymentRepository();

  final RxBool isLoading = false.obs;
  final RxString selectedRole = AppConstants.roleBachelor.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  final RxBool obscureLoginPassword = true.obs;
  final RxBool obscureSignupPassword = true.obs;

  void toggleLoginPasswordVisibility() {
    obscureLoginPassword.toggle();
  }

  void toggleSignupPasswordVisibility() {
    obscureSignupPassword.toggle();
  }

  void setRole(String role) {
    selectedRole.value = role;
    obscureLoginPassword.value = true;
    Get.to(() => const LoginScreen(), transition: Transition.rightToLeft);
  }

  static String _formatEmailToName(String email) {
    if (!email.contains('@')) return 'Bachelor Tenant';
    final prefix = email.split('@').first;
    final cleaned = prefix.replaceAll(RegExp(r'[^a-zA-Z]'), ' ').trim();
    if (cleaned.isEmpty) return 'Bachelor Tenant';
    return cleaned
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      ApiChecker.checkApi('Please enter email and password');
      return;
    }
    isLoading.value = true;
    try {
      final credential =
          await _authRepo.login(email: email, password: password);
      if (credential?.user != null) {
        final userData = await _authRepo.getUserData(credential!.user!.uid);
        if (userData != null) {
          UserModel updatedUser = userData;

          // Auto-repair profile name if it was previously saved as 'User' or empty
          if (updatedUser.name.trim().isEmpty ||
              updatedUser.name.trim().toLowerCase() == 'user') {
            final betterName = (credential.user!.displayName != null &&
                    credential.user!.displayName!.trim().isNotEmpty &&
                    credential.user!.displayName!.trim().toLowerCase() !=
                        'user')
                ? credential.user!.displayName!.trim()
                : _formatEmailToName(email);
            updatedUser = updatedUser.copyWith(name: betterName);
            await _authRepo.saveUserData(updatedUser);
          }

          // Sync role: update users doc if selected role is different
          if (selectedRole.value != AppConstants.roleAdmin &&
              userData.role != selectedRole.value) {
            updatedUser = updatedUser.copyWith(role: selectedRole.value);
            await _authRepo.saveUserData(updatedUser);
          }

          // Always verify real payment approval from payments collection for the SELECTED ROLE
          // This supports one account being both landlord AND bachelor independently
          if (selectedRole.value != AppConstants.roleAdmin) {
            final payment = await _paymentRepo.getMyPaymentStatus(
              updatedUser.uid,
              role: selectedRole.value,
            );
            final bool approvedForThisRole =
                payment != null && payment.isApproved;

            if (approvedForThisRole != updatedUser.isPaid) {
              updatedUser = updatedUser.copyWith(isPaid: approvedForThisRole);
              await _authRepo.saveUserData(updatedUser);
            }
          }

          currentUser.value = updatedUser;
          ApiChecker.showSuccess('Welcome back, ${updatedUser.name}!');
          handleNavigation(updatedUser);
        } else if (selectedRole.value == AppConstants.roleAdmin) {
          final adminUser = UserModel(
            uid: credential.user!.uid,
            name: 'System Admin',
            phone: '01868569162',
            role: AppConstants.roleAdmin,
            isPaid: true,
            createdAt: DateTime.now(),
          );
          await _authRepo.saveUserData(adminUser);
          currentUser.value = adminUser;
          ApiChecker.showSuccess('Welcome, System Admin!');
          handleNavigation(adminUser);
        } else {
          // Automatic recovery if user registered before Firestore was created
          final recoveredName = (credential.user!.displayName != null &&
                  credential.user!.displayName!.trim().isNotEmpty &&
                  credential.user!.displayName!.trim().toLowerCase() != 'user')
              ? credential.user!.displayName!.trim()
              : _formatEmailToName(email);
          final recoveredUser = UserModel(
            uid: credential.user!.uid,
            name: recoveredName,
            phone: '',
            role: selectedRole.value,
            isPaid: false,
            createdAt: DateTime.now(),
          );
          await _authRepo.saveUserData(recoveredUser);
          currentUser.value = recoveredUser;
          ApiChecker.showSuccess('Welcome back, $recoveredName!');
          handleNavigation(recoveredUser);
        }
      }
    } catch (e) {
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      ApiChecker.checkApi('Please fill in all fields correctly');
      return;
    }
    isLoading.value = true;
    try {
      final credential =
          await _authRepo.signUp(email: email, password: password);
      if (credential?.user != null) {
        try {
          await credential!.user!.updateDisplayName(name.trim());
        } catch (_) {}
        final newUser = UserModel(
          uid: credential!.user!.uid,
          name: name.trim(),
          phone: phone.trim(),
          role: selectedRole.value,
          isPaid: false,
          createdAt: DateTime.now(),
        );
        await _authRepo.saveUserData(newUser);
        currentUser.value = newUser;
        ApiChecker.showSuccess('Account created successfully!');
        handleNavigation(newUser);
      }
    } catch (e) {
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword(String email) async {
    if (email.trim().isEmpty) {
      ApiChecker.checkApi('Please enter your email address');
      return;
    }
    if (!GetUtils.isEmail(email.trim())) {
      ApiChecker.checkApi('Please enter a valid email address');
      return;
    }
    isLoading.value = true;
    try {
      await _authRepo.sendPasswordResetEmail(email.trim());
      ApiChecker.showSuccess(
        'Password reset link sent to your email! Please check your inbox.',
        title: 'Reset Link Sent',
      );
      Get.back();
    } catch (e) {
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  void handleNavigation(UserModel user) {
    if (user.isAdmin || selectedRole.value == AppConstants.roleAdmin) {
      // Step 4 - Navigate to Admin Dashboard
      Get.offAll(() => const AdminDashboardScreen(),
          transition: Transition.rightToLeft);
    } else {
      // Action-based payment model: users explore app immediately!
      Get.offAll(() => UserHomeScreen(user: user),
          transition: Transition.rightToLeft);
    }
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    String? photoUrl,
  }) async {
    final user = currentUser.value;
    if (user == null) {
      ApiChecker.showError('Session expired. Please log in again');
      return;
    }
    try {
      isLoading.value = true;
      final updatedUser = user.copyWith(
        name: name.trim(),
        phone: phone.trim(),
        photoUrl: photoUrl ?? user.photoUrl,
      );
      await _authRepo.saveUserData(updatedUser);
      currentUser.value = updatedUser;
      currentUser.refresh();
      ApiChecker.showSuccess('Profile updated successfully!');
      Get.back();
    } catch (e) {
      ApiChecker.showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    currentUser.value = null;
    Get.offAll(() => const RoleSelectionScreen(),
        transition: Transition.fadeIn);
  }
}
