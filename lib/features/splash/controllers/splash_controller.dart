import 'package:get/get.dart';
import '../../../core/middlewares/auth_middleware.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    await AuthMiddleware.checkAuthAndNavigate();
  }
}
