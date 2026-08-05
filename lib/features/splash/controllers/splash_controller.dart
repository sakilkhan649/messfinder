import 'package:get/get.dart';
import '../../auth/views/role_selection_screen.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    Get.off(() => const RoleSelectionScreen(), transition: Transition.fadeIn);
  }
}
