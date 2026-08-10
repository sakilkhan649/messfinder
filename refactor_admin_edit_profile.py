import re

filepath = r"d:\sakil\mess_finder\lib\features\admin\views\admin_edit_profile_screen.dart"

with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

# Change to StatelessWidget
content = re.sub(r'class AdminEditProfileScreen extends StatefulWidget \{.*?\n\}', 
'''class AdminEditProfileScreen extends StatelessWidget {
  final UserModel user;

  const AdminEditProfileScreen({super.key, required this.user});

  AdminEditProfileController get controller => Get.find<AdminEditProfileController>(tag: 'admin_edit_profile');
''', content, flags=re.DOTALL)

# Remove State class up to build
content = re.sub(r'class _AdminEditProfileScreenState extends State<AdminEditProfileScreen> \{.*?(?=@override\s*Widget build\(BuildContext context\))', 
'''  ''', content, flags=re.DOTALL)

# Replace properties in the class
content = content.replace('''widget.user''', '''user''')
content = content.replace('''_formKey''', '''controller.formKey''')
content = content.replace('''_nameController''', '''controller.nameController''')
content = content.replace('''_phoneController''', '''controller.phoneController''')
content = content.replace('''_pickImageFromGallery''', '''controller.pickImageFromGallery''')
content = content.replace('''_submitUpdate''', '''controller.submitUpdate''')

# Build method prefix
content = re.sub(r'(@override\s*Widget build\(BuildContext context\) \{)', 
r'\1\n    Get.put(AdminEditProfileController(user), tag: \'admin_edit_profile\');', content)

# Obx for Image
content = content.replace('''child: _selectedImageFile != null
                                          ? Image.file(
                                              _selectedImageFile!,''',
                                          '''child: Obx(() => controller.selectedImageFile.value != null
                                          ? Image.file(
                                              controller.selectedImageFile.value!,''')

content = content.replace('''                                                color: Colors.grey.shade400,
                                              ),''',
                                          '''                                                color: Colors.grey.shade400,
                                              )))''')

controller_class = '''
class AdminEditProfileController extends GetxController {
  final UserModel user;
  
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  
  final ImagePicker _picker = ImagePicker();
  final Rx<File?> selectedImageFile = Rx<File?>(null);

  AdminEditProfileController(this.user);

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController(text: user.name);
    phoneController = TextEditingController(text: user.phone);
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        selectedImageFile.value = File(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not load image from gallery: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void submitUpdate() {
    if (formKey.currentState!.validate()) {
      final authController = Get.find<AuthController>();
      authController.updateProfile(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        photoUrl: selectedImageFile.value?.path ?? user.photoUrl,
      );
    }
  }
}
'''

content += controller_class

with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)

print("Done")
