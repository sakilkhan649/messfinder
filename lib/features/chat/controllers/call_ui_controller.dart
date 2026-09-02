import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CallUIController extends GetxController with GetSingleTickerProviderStateMixin {
  final showControls = true.obs;
  final pipPosition = Rx<Offset?>(null);
  
  late AnimationController pulseController;
  late Animation<double> pulseAnimation;

  @override
  void onInit() {
    super.onInit();
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);
    
    pulseAnimation = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void onClose() {
    pulseController.dispose();
    super.onClose();
  }

  void toggleControls() {
    showControls.value = !showControls.value;
  }

  void updatePipPosition(Offset delta) {
    if (pipPosition.value != null) {
      pipPosition.value = pipPosition.value! + delta;
    }
  }
}
