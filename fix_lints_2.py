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
    ("_adminController", "adminController")
])

# 2. otp_verification_screen.dart
fix_file(r"d:\sakil\mess_finder\lib\features\auth\views\otp_verification_screen.dart", [
    ("_authController", "authController")
])

# 3. phone_login_screen.dart
fix_file(r"d:\sakil\mess_finder\lib\features\auth\views\phone_login_screen.dart", [
    ("_authController", "authController")
])

# 4. mess_map_screen.dart
fix_file(r"d:\sakil\mess_finder\lib\features\bachelor\views\mess_map_screen.dart", [
    ("_postController", "postController"),
    ("_mapController", "mapController")
])

# 5. my_bookings_screen.dart
fix_file(r"d:\sakil\mess_finder\lib\features\bachelor\views\my_bookings_screen.dart", [
    ("ownerPhotoUrl == null || ownerPhotoUrl!.isEmpty", "ownerPhotoUrl == null || ownerPhotoUrl.isEmpty")
])

# 6. chat_screen.dart
fix_file(r"d:\sakil\mess_finder\lib\features\chat\views\chat_screen.dart", [
    ("message.imageUrl != null ? '${message.imageUrl}' : 'Image'", "message.imageUrl != null ? message.imageUrl! : 'Image'")
])

# 7. map_location_picker_screen.dart
fix_file(r"d:\sakil\mess_finder\lib\features\landlord\views\map_location_picker_screen.dart", [
    ("_mapController", "mapController")
])

print("Finished script execution 2.")
