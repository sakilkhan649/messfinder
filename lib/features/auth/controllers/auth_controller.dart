import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/network/api_checker.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/services/media_upload_service.dart';
import '../../admin/views/admin_dashboard_screen.dart';
import '../../home/views/user_home_screen.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../models/user_model.dart';
import '../repositories/auth_repo.dart';
import '../views/login_screen.dart';
import '../../chat/controllers/call_controller.dart';
import '../../chat/views/call_screen.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();

  final RxBool isLoading = false.obs;
  final RxString selectedRole = AppConstants.roleUser.obs;
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

  // Google Sign-In via Native Google Play Services
  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        isLoading.value = false;
        return;
      }

      final googleUserEmail = googleUser.email;
      final googleUserName = googleUser.displayName ?? 'Google User';
      final googleUserPhoto = googleUser.photoUrl;
      final googleUserId = googleUser.id;

      final updatedUser = await _authRepo.googleLogin(
        email: googleUserEmail,
        name: googleUserName,
        profileImage: googleUserPhoto,
        googleId: googleUserId,
        role: selectedRole.value,
      );

      if (updatedUser != null) {
        currentUser.value = updatedUser;
        ApiChecker.showSuccess('Welcome, ${updatedUser.name}!');
        handleNavigation(updatedUser);
      }
    } catch (e) {
      AppLogger.e('Google sign-in error: $e', e, null, 'AUTH_CTRL');
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      ApiChecker.checkApi('Please enter email and password');
      return;
    }
    isLoading.value = true;
    try {
      final updatedUser = await _authRepo.login(email: email, password: password);
      
      if (updatedUser != null) {
        currentUser.value = updatedUser;
        ApiChecker.showSuccess('Welcome back, ${updatedUser.name}!');
        handleNavigation(updatedUser);
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
      final newUser = await _authRepo.signUp(
        name: name.trim(),
        phone: phone.trim(),
        email: email.trim(),
        password: password,
      );
      
      if (newUser != null) {
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
    isLoading.value = true;
    try {
      await _authRepo.sendPasswordResetEmail(email.trim());
      ApiChecker.showSuccess('Password reset link sent to your email!');
      Get.back();
    } catch (e) {
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final isLoggedIn = await _authRepo.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authRepo.getUserData('me');
        if (user != null) {
          currentUser.value = user;
          handleNavigation(user);
        } else {
          await _authRepo.logout();
          Get.offAll(() => const LoginScreen());
        }
      } else {
        Get.offAll(() => const LoginScreen());
      }
    } catch (e) {
      await _authRepo.logout();
      Get.offAll(() => const LoginScreen());
    }
  }
  void handleNavigation(UserModel user) async {
    // Save FCM token & subscribe to role-based topic
    _setupNotificationsForUser(user);

    final currentRoute = Get.currentRoute;
    final isCallActive = currentRoute == '/CallScreen' || currentRoute == '/IncomingCallScreen';

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

    if (isCallActive) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (Get.isRegistered<CallController>()) {
        final callCtrl = Get.find<CallController>();
        if (callCtrl.callState.value != CallState.idle) {
          if (currentRoute == '/CallScreen') {
            Get.to(() => const CallScreen(), routeName: '/CallScreen');
          }
        }
      }
    }
  }

  Future<void> _setupNotificationsForUser(UserModel user) async {
    final notifService = NotificationService();
    // Save FCM token to backend
    await notifService.saveTokenToBackend();
    // Subscribe to topic for broadcast notifications
    await notifService.subscribeToTopic('all_users');
    if (user.role.isNotEmpty) {
      await notifService.subscribeToTopic(user.role.toLowerCase());
    }
    // Start listening to in-app notifications
    if (Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().listenForUser(user.uid, role: user.role);
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
          final storageService = MediaUploadService();
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
