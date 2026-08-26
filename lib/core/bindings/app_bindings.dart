import 'package:get/get.dart';
import '../network/network_controller.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/splash/controllers/splash_controller.dart';
import '../../features/landlord/controllers/post_controller.dart';
import '../../features/chat/controllers/chat_controller.dart';
import '../../features/chat/controllers/call_controller.dart';
import '../../features/payment/controllers/payment_controller.dart';
import '../../features/admin/controllers/admin_controller.dart';
import '../../features/landlord/controllers/tenant_leads_controller.dart';
import '../../features/notifications/controllers/notification_controller.dart';
import '../../features/marketplace/controllers/marketplace_controller.dart';
import '../../features/home/controllers/user_home_controller.dart';
import '../../core/services/socket_service.dart';
import '../../features/bachelor/controllers/bachelor_main_controller.dart';
import '../../features/bachelor/views/mess_map_screen.dart'; // Contains MessMapController
import '../../features/onboarding/controllers/onboarding_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(NetworkController(), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(NotificationController(), permanent: true);
    Get.put(CallController(), permanent: true);
    Get.put(SocketService(), permanent: true);
    
    // Features (Lazy loaded, fenix: true ensures they are recreated if needed after being disposed)
    Get.lazyPut(() => SplashController(), fenix: true);
    Get.lazyPut(() => PostController(), fenix: true);
    Get.lazyPut(() => ChatController(), fenix: true);
    Get.lazyPut(() => PaymentController(), fenix: true);
    Get.lazyPut(() => AdminController(), fenix: true);
    Get.lazyPut(() => TenantLeadsController(), fenix: true);
    
    // Newly Added Controllers for Global Binding
    Get.lazyPut(() => MarketplaceController(), fenix: true);
    Get.lazyPut(() => UserHomeController(), fenix: true);
    Get.lazyPut(() => BachelorMainController(), fenix: true);
    Get.lazyPut(() => MessMapController(), fenix: true);
    Get.lazyPut(() => OnboardingController(), fenix: true);
  }
}
