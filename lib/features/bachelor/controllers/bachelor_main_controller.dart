import 'package:get/get.dart';

class BachelorMainController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RxBool isBottomNavVisible = true.obs;

  void setIndex(int index) {
    currentIndex.value = index;
  }

  void setNavVisible(bool visible) {
    if (isBottomNavVisible.value != visible) {
      isBottomNavVisible.value = visible;
    }
  }
}
