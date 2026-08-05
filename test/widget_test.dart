import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mess_finder/core/utils/app_constants.dart';
import 'package:mess_finder/main.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('MessFinderApp smoke test - splash screen check and settle',
      (WidgetTester tester) async {
    await ScreenUtil.ensureScreenSize();

    // Build our app and trigger initial frame.
    await tester.pumpWidget(const MessFinderApp());

    // Verify that SplashScreen title appears initially
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(AppConstants.appTagline), findsOneWidget);

    // Pump and settle to let the SplashController 2.5s timer finish cleanly
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
