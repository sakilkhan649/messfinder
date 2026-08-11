import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mess_finder/core/utils/api_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/network/api_checker.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/utils/imgbb_service.dart';
import '../../admin/views/admin_dashboard_screen.dart';
import '../../home/views/user_home_screen.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../models/user_model.dart';
import '../repositories/auth_repo.dart';
import '../views/login_screen.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();

  final RxBool isLoading = false.obs;
  final RxString selectedRole = AppConstants.roleBachelor.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  final RxBool obscureLoginPassword = true.obs;
  final RxBool obscureSignupPassword = true.obs;

  // Phone Auth state
  final RxString verificationId = ''.obs;
  final RxInt resendToken = 0.obs;

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
          // IMPORTANT: Never override an admin user's role
          if (userData.role != AppConstants.roleAdmin &&
              selectedRole.value != AppConstants.roleAdmin &&
              userData.role != selectedRole.value) {
            updatedUser = updatedUser.copyWith(role: selectedRole.value);
            await _authRepo.saveUserData(updatedUser);
          }

          // If logging in via admin dialog but role was corrupted, restore it
          if (selectedRole.value == AppConstants.roleAdmin &&
              updatedUser.role != AppConstants.roleAdmin) {
            updatedUser = updatedUser.copyWith(role: AppConstants.roleAdmin);
            await _authRepo.saveUserData(updatedUser);
          }

          if (selectedRole.value != AppConstants.roleAdmin) {
            if (!updatedUser.isPaid) {
              updatedUser = updatedUser.copyWith(isPaid: true);
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
    // Save FCM token & subscribe to role-based topic
    _setupNotificationsForUser(user);

    // Always use the actual user role from Firestore, NOT selectedRole
    if (user.isAdmin) {
      Get.offAll(() => const AdminDashboardScreen(),
          transition: Transition.rightToLeft);
    } else {
      // Reset selectedRole to match actual user role
      selectedRole.value = user.role;
      Get.offAll(() => UserHomeScreen(user: user),
          transition: Transition.rightToLeft);
    }
  }

  Future<void> _setupNotificationsForUser(UserModel user) async {
    final notifService = NotificationService();
    // Save FCM token to Firestore
    await notifService.saveTokenToFirestore(user.uid);
    // Subscribe to role-based topic for broadcast notifications
    await notifService.subscribeToTopic('all_users');
    if (user.isBachelor) {
      await notifService.subscribeToTopic('bachelors');
      await notifService.unsubscribeFromTopic('landlords');
    } else if (user.isLandlord) {
      await notifService.subscribeToTopic('landlords');
      await notifService.unsubscribeFromTopic('bachelors');
    }
    // Start listening to in-app notifications
    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().listenForUser(user.uid);
    }
  }

  Future<void> switchRole(String newRole) async {
    final user = currentUser.value;
    if (user != null && user.role != newRole) {
      isLoading.value = true;
      try {
        selectedRole.value = newRole;
        UserModel updatedUser = user.copyWith(role: newRole);
        
        // Check payment status for the new role
        if (newRole != AppConstants.roleAdmin) {
          updatedUser = updatedUser.copyWith(isPaid: true);
        }
        
        await _authRepo.saveUserData(updatedUser);
        currentUser.value = updatedUser;
        handleNavigation(updatedUser);
      } catch (e) {
        ApiChecker.showError('Failed to switch role: $e');
      } finally {
        isLoading.value = false;
      }
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
      
      String? finalPhotoUrl = user.photoUrl;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
          finalPhotoUrl = photoUrl;
        } else {
          final storageService = ImgbbService();
          final uploadedUrl = await storageService.uploadImage(photoUrl);
          if (uploadedUrl != null) {
            finalPhotoUrl = uploadedUrl;
          }
        }
      }

      final updatedUser = user.copyWith(
        name: name.trim(),
        phone: phone.trim(),
        photoUrl: finalPhotoUrl,
      );
      await _authRepo.saveUserData(updatedUser);
      
      // Update cached names and photos in all chat rooms
      try {
        final chatRoomsSnapshot = await FirebaseFirestore.instance
            .collection(ApiConstants.chatsCollection)
            .where('participants', arrayContains: user.uid)
            .get();
            
        if (chatRoomsSnapshot.docs.isNotEmpty) {
          final batch = FirebaseFirestore.instance.batch();
          for (var doc in chatRoomsSnapshot.docs) {
            batch.update(doc.reference, {
              'participantNames.${user.uid}': updatedUser.name,
              if (updatedUser.photoUrl != null)
                'participantPhotos.${user.uid}': updatedUser.photoUrl,
            });
          }
          await batch.commit();
        }
      } catch (e) {
        AppLogger.e('Failed to update chat rooms cache', e, null, 'AUTH_CTRL');
      }

      currentUser.value = updatedUser;
      currentUser.refresh();
      Get.back();
      ApiChecker.showSuccess('Profile updated successfully!');
    } catch (e) {
      ApiChecker.showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    currentUser.value = null;
    selectedRole.value = AppConstants.roleBachelor;
    Get.offAll(() => const LoginScreen(),
        transition: Transition.fadeIn);
  }

  Future<void> deleteMyAccount() async {
    final user = currentUser.value;
    if (user == null) {
      ApiChecker.showError('Session expired. Please log in again.');
      return;
    }
    
    isLoading.value = true;
    try {
      await _authRepo.deleteCurrentAccount(user.uid);
      currentUser.value = null;
      selectedRole.value = AppConstants.roleBachelor;
      ApiChecker.showSuccess('Your account has been deleted successfully.');
      Get.offAll(() => const LoginScreen(), transition: Transition.fadeIn);
    } catch (e) {
      ApiChecker.showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUserData(String uid) async {
    try {
      final userData = await _authRepo.getUserData(uid);
      if (userData != null) {
        currentUser.value = userData;
      }
    } catch (e) {
      AppLogger.e('Failed to fetch user data: $e', e, null, 'AUTH_CTRL');
    }
  }

  // ================= PHONE AUTHENTICATION =================

  Future<void> verifyPhoneNumber(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ApiChecker.checkApi('Please enter a valid phone number');
      return;
    }
    
    // Auto-prepend +880 if missing and number starts with 01
    String formattedPhone = phoneNumber.trim();
    if (formattedPhone.startsWith('01') && formattedPhone.length == 11) {
      formattedPhone = '+88$formattedPhone';
    }

    isLoading.value = true;
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential, formattedPhone);
        },
        verificationFailed: (FirebaseAuthException e) {
          isLoading.value = false;
          AppLogger.e('Phone Auth Failed: ${e.message}', e, null, 'AUTH_CTRL');
          ApiChecker.checkApi(e.message ?? 'Verification failed');
        },
        codeSent: (String vId, int? token) {
          verificationId.value = vId;
          resendToken.value = token ?? 0;
          isLoading.value = false;
          ApiChecker.showSuccess('OTP Sent Successfully!');
          // We will navigate to OtpVerificationScreen from the view, or we can do it here
          // Get.to(() => OtpVerificationScreen(phone: formattedPhone), transition: Transition.rightToLeft);
        },
        codeAutoRetrievalTimeout: (String vId) {
          verificationId.value = vId;
        },
        forceResendingToken: resendToken.value == 0 ? null : resendToken.value,
      );
    } catch (e) {
      isLoading.value = false;
      ApiChecker.checkApi(e.toString());
    }
  }

  Future<void> verifyOTP(String otp, String phone) async {
    if (otp.isEmpty || otp.length < 6) {
      ApiChecker.checkApi('Please enter a valid 6-digit OTP');
      return;
    }
    isLoading.value = true;
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: otp,
      );
      await _signInWithCredential(credential, phone);
    } catch (e) {
      isLoading.value = false;
      ApiChecker.checkApi('Invalid OTP. Please check and try again.');
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential, String phone) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        final userData = await _authRepo.getUserData(userCredential.user!.uid);
        if (userData != null) {
          // Existing User
          UserModel updatedUser = userData;
          if (selectedRole.value != AppConstants.roleAdmin && userData.role != selectedRole.value) {
            updatedUser = updatedUser.copyWith(role: selectedRole.value);
            await _authRepo.saveUserData(updatedUser);
          }
          
          if (selectedRole.value != AppConstants.roleAdmin) {
            if (!updatedUser.isPaid) {
              updatedUser = updatedUser.copyWith(isPaid: true);
              await _authRepo.saveUserData(updatedUser);
            }
          }
          
          currentUser.value = updatedUser;
          isLoading.value = false;
          ApiChecker.showSuccess('Welcome back, ${updatedUser.name}!');
          handleNavigation(updatedUser);
        } else {
          // New User
          final newUser = UserModel(
            uid: userCredential.user!.uid,
            name: 'User_${phone.substring(phone.length - 4)}',
            phone: phone,
            role: selectedRole.value,
            isPaid: true,
            createdAt: DateTime.now(),
          );
          await _authRepo.saveUserData(newUser);
          currentUser.value = newUser;
          isLoading.value = false;
          ApiChecker.showSuccess('Account created successfully!');
          handleNavigation(newUser);
        }
      }
    } catch (e) {
      isLoading.value = false;
      ApiChecker.checkApi('Failed to sign in. Please try again.');
    }
  }
}
