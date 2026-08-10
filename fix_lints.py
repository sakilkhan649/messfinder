import re

def fix_file(path, replacements):
    try:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
            
        for old, new in replacements:
            content = content.replace(old, new)
            
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Fixed {path}")
    except Exception as e:
        print(f"Error processing {path}: {e}")

# 1. admin_dashboard_screen.dart
fix_file(r"d:\sakil\mess_finder\lib\features\admin\views\admin_dashboard_screen.dart", [
    ("final _adminController = Get.find<AdminController>();", "final adminController = Get.find<AdminController>();"),
    ("_adminController.currentNavIndex.value;", "adminController.currentNavIndex.value;"),
    ("AdminOverviewTab(controller: _adminController),", "AdminOverviewTab(controller: adminController),"),
    ("AdminRequestsTab(controller: _adminController),", "AdminRequestsTab(controller: adminController),"),
    ("AdminUsersTab(controller: _adminController),", "AdminUsersTab(controller: adminController),"),
    ("_buildAppBar(_adminController)", "_buildAppBar(adminController)"),
    ("_buildBottomNav(_adminController)", "_buildBottomNav(adminController)"),
    ("_buildAppBar(AdminController _adminController)", "_buildAppBar(AdminController adminController)"),
    ("_buildBottomNav(AdminController _adminController)", "_buildBottomNav(AdminController adminController)"),
    ("bottomNavigationBar: _buildBottomNav(adminController),", "bottomNavigationBar: _buildBottomNav(adminController),"),
    ("return BottomNavigationBar(", "return BottomNavigationBar("),
    ("currentIndex: _adminController.currentNavIndex.value,", "currentIndex: adminController.currentNavIndex.value,"),
    ("onTap: _adminController.changeNavIndex,", "onTap: adminController.changeNavIndex,")
])

# 2. forgot_password_screen.dart
fix_file(r"d:\sakil\mess_finder\lib\features\auth\views\forgot_password_screen.dart", [
    ("import '../controllers/auth_controller.dart';\n", "")
])

# 3. otp_verification_screen.dart
fix_file(r"d:\sakil\mess_finder\lib\features\auth\views\otp_verification_screen.dart", [
    ("import 'dart:async';\n", ""),
    ("final _authController = Get.find<OtpVerificationController>();", "final authController = Get.find<OtpVerificationController>();"),
    ("_authController.verifyOtp(", "authController.verifyOtp("),
    ("_authController.isLoading.value", "authController.isLoading.value"),
    ("_authController.isResending.value", "authController.isResending.value"),
    ("_authController.resendOtp(", "authController.resendOtp("),
    ("_authController.otpController,", "authController.otpController,")
])

# 4. phone_login_screen.dart
fix_file(r"d:\sakil\mess_finder\lib\features\auth\views\phone_login_screen.dart", [
    ("import '../controllers/auth_controller.dart';\n", ""),
    ("import 'otp_verification_screen.dart';\n", ""),
    ("final _authController = Get.find<PhoneLoginController>();", "final authController = Get.find<PhoneLoginController>();"),
    ("_authController.sendOtp()", "authController.sendOtp()"),
    ("_authController.isLoading.value", "authController.isLoading.value"),
    ("_authController.phoneController,", "authController.phoneController,")
])

# 5. signup_screen.dart
fix_file(r"d:\sakil\mess_finder\lib\features\auth\views\signup_screen.dart", [
    ("import '../controllers/auth_controller.dart';\n", "")
])

# 6. mess_map_screen.dart
fix_file(r"d:\sakil\mess_finder\lib\features\bachelor\views\mess_map_screen.dart", [
    ("final _postController = Get.find<PostController>();", "final postController = Get.find<PostController>();"),
    ("final _mapController = Get.put(MessMapController());", "final mapController = Get.put(MessMapController());"),
    ("_postController.posts", "postController.posts"),
    ("_mapController.mapController", "mapController.mapController"),
    ("_mapController.setMapController(", "mapController.setMapController("),
    ("_mapController.centerLocation", "mapController.centerLocation")
])

# 7. my_bookings_screen.dart
fix_file(r"d:\sakil\mess_finder\lib\features\bachelor\views\my_bookings_screen.dart", [
    ("ownerPhotoUrl == null || ownerPhotoUrl!.isEmpty", "ownerPhotoUrl == null || ownerPhotoUrl.isEmpty")
])

# 8. chat_screen.dart
fix_file(r"d:\sakil\mess_finder\lib\features\chat\views\chat_screen.dart", [
    ("onTap: () => _showImagePreview(context, '${message.imageUrl}', _chatController),", "onTap: () => _showImagePreview(context, message.imageUrl!, _chatController),"),
    ("onTap: () => _showImagePreview(context, message.imageUrl, _chatController),", "onTap: () => _showImagePreview(context, message.imageUrl!, _chatController),")
])

# 9. add_post_screen.dart
fix_file(r"d:\sakil\mess_finder\lib\features\landlord\views\add_post_screen.dart", [
    ("import 'package:image_picker/image_picker.dart';\n", ""),
    ("import '../../../core/utils/app_constants.dart';\n", "")
])

# 10. map_location_picker_screen.dart
fix_file(r"d:\sakil\mess_finder\lib\features\landlord\views\map_location_picker_screen.dart", [
    ("final _mapController = Get.find<MapPickerController>();", "final mapController = Get.find<MapPickerController>();"),
    ("_mapController.initialLocation", "mapController.initialLocation"),
    ("_mapController.onMapCreated", "mapController.onMapCreated"),
    ("_mapController.updateLocation", "mapController.updateLocation"),
    ("_mapController.isConfirming.value", "mapController.isConfirming.value"),
    ("_mapController.confirmLocation()", "mapController.confirmLocation()")
])

# 11. edit_profile_screen.dart
fix_file(r"d:\sakil\mess_finder\lib\features\profile\views\edit_profile_screen.dart", [
    ("import 'dart:io';\n", ""),
    ("import 'package:image_picker/image_picker.dart';\n", "")
])

print("Finished script execution.")
