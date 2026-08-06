import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_constants.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/splash/bindings/splash_binding.dart';
import 'features/splash/views/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/network/network_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Gracefully handle test environment where native Firebase channels are absent
    debugPrint('Firebase init notice (test/dev fallback): $e');
  }

  // Register Controllers globally
  Get.put(NetworkController(), permanent: true);
  Get.put(AuthController(), permanent: true);

  runApp(const MessFinderApp());
}

class MessFinderApp extends StatelessWidget {
  const MessFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialBinding: SplashBinding(),
          defaultTransition: Transition.fadeIn,
          home: const SplashScreen(),
        );
      },
    );
  }
}
