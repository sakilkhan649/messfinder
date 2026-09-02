import 'package:get/get.dart';
import '../../../core/middlewares/auth_middleware.dart';
import '../../../core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import '../../onboarding/views/onboarding_screen.dart';
import '../../chat/controllers/call_controller.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // Initialize NotificationService immediately so CallKit event listeners
    // are registered BEFORE we check activeCalls or navigate.
    // Previously, initialize() was in onReady() which fired AFTER _navigateToNext()
    // started, causing a race condition where Home was shown instead of CallScreen.
    NotificationService().initialize();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Check if the app was launched from a terminated state by a CallKit accept.
    // We must detect this EARLY (before any navigation) to prevent HomeScreen flash.
    bool hasActiveCall = false;
    try {
      final activeCalls = await FlutterCallkitIncoming.activeCalls();
      if (activeCalls.isNotEmpty) {
        hasActiveCall = true;

        // Pre-populate CallController with call data from the active CallKit call.
        // This ensures AuthController.handleNavigation() detects the call state
        // even before the CallEventActionCallAccept event fires.
        if (Get.isRegistered<CallController>()) {
          final callCtrl = Get.find<CallController>();
          if (callCtrl.callState.value == CallState.idle) {
            final call = activeCalls[0];
            final extra = call.extra;
            callCtrl.currentChannel = (extra != null ? extra['relatedId'] : null) ?? '';
            callCtrl.isVideoCall.value = extra != null && extra['isVideo'] == true;
            callCtrl.peerUserId = (extra != null ? extra['senderUid'] : null) ?? '';
            callCtrl.peerUserName = call.nameCaller ?? 'Unknown Caller';
            callCtrl.peerUserPhoto = call.avatar;
            // Set callState LAST so it's fully populated when checked
            callCtrl.callState.value = CallState.incoming;
            callCtrl.callStatusText.value = 'Incoming Call...';
          }
        }
      }
    } catch (e) {
      // ignore — activeCalls() not available on all platforms
    }

    if (hasActiveCall) {
      // App was launched because user accepted/declined a call.
      // Do NOT navigate to home. The CallKit event handler in NotificationService
      // will call acceptCall() which navigates to CallScreen.
      // We just wait here by doing auth check (which will detect call & abort home nav).
      await Future.delayed(const Duration(milliseconds: 500));
      // Fall through to auth check — handleNavigation() will detect callState != idle
      // and abort Home navigation automatically.
    } else {
      // Normal app launch — standard splash delay
      await Future.delayed(const Duration(milliseconds: 2000));
    }
    
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!hasSeenOnboarding) {
      Get.off(() => const OnboardingScreen(), transition: Transition.fadeIn);
    } else {
      await AuthMiddleware.checkAuthAndNavigate();
    }
  }
}
