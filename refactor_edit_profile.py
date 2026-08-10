import re
import os

filepath = r"d:\sakil\mess_finder\lib\features\profile\views\edit_profile_screen.dart"

with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

# Replace imports
content = content.replace("import '../../auth/controllers/auth_controller.dart';", "import '../controllers/edit_profile_controller.dart';\nimport '../../auth/controllers/auth_controller.dart';")

# Change to StatelessWidget
content = re.sub(r'class EditProfileScreen extends StatefulWidget \{.*?\n\}', 
'''class EditProfileScreen extends StatelessWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});''', content, flags=re.DOTALL)

# Find where _buildLabel starts
# Remove everything from class _EditProfileScreenState up to @override Widget build
content = re.sub(r'class _EditProfileScreenState extends State<EditProfileScreen> \{.*?@override\s*Widget build\(BuildContext context\) \{', 
'''  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditProfileController(user: user));''', content, flags=re.DOTALL)

# Replace variables and methods
replacements = {
    r'_formKey': r'controller.formKey',
    r'_nameController': r'controller.nameController',
    r'_phoneController': r'controller.phoneController',
    r'_pickImageFromGallery': r'controller.pickImageFromGallery',
    r'_submit': r'controller.submit',
    r'widget\.user': r'user',
}

for k, v in replacements.items():
    content = re.sub(k, v, content)

# Wrap image with Obx
content = content.replace('''                        child: ClipOval(
                          child: _selectedImageFile != null
                              ? Image.file(
                                  _selectedImageFile!,''',
'''                        child: Obx(() => ClipOval(
                          child: controller.selectedImageFile.value != null
                              ? Image.file(
                                  controller.selectedImageFile.value!,''')

content = content.replace('''                                      Icons.person_rounded,
                                      size: 55.r,
                                      color: Colors.grey.shade400,
                                    ),
                        ),''',
'''                                      Icons.person_rounded,
                                      size: 55.r,
                                      color: Colors.grey.shade400,
                                    ),
                        )),''')

with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)

print("Done")
