import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CallUIController extends GetxController {
  final showControls = true.obs;
  final pipPosition = Rx<Offset?>(null);

  void toggleControls() {
    showControls.value = !showControls.value;
  }

  void updatePipPosition(Offset delta) {
    if (pipPosition.value != null) {
      pipPosition.value = pipPosition.value! + delta;
    }
  }
}
