import 'package:get/get.dart';

import '../network/network_controller.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/splash/controllers/splash_controller.dart';
import '../../features/landlord/controllers/post_controller.dart';
import '../../features/chat/controllers/chat_controller.dart';
import '../../features/payment/controllers/payment_controller.dart';
import '../../features/admin/controllers/admin_controller.dart';
import '../../features/landlord/controllers/tenant_leads_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Core & Authentication (Permanent)
    Get.put(NetworkController(), permanent: true);
    Get.put(AuthController(), permanent: true);
    
    // Features (Lazy loaded, fenix: true ensures they are recreated if needed after being disposed)
    Get.lazyPut(() => SplashController(), fenix: true);
    Get.lazyPut(() => PostController(), fenix: true);
    Get.lazyPut(() => ChatController(), fenix: true);
    Get.lazyPut(() => PaymentController(), fenix: true);
    Get.lazyPut(() => AdminController(), fenix: true);
    Get.lazyPut(() => TenantLeadsController(), fenix: true);
  }
}
