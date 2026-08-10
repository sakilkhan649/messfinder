import re
import os

filepath = r"d:\sakil\mess_finder\lib\features\landlord\views\add_post_screen.dart"

with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

# Replace imports
content = content.replace("import '../controllers/post_controller.dart';", "import '../controllers/add_post_controller.dart';\nimport '../controllers/post_controller.dart';")

# Change to StatelessWidget
content = re.sub(r'class AddPostScreen extends StatefulWidget \{.*?\n\}', 
'''class AddPostScreen extends StatelessWidget {
  final PostModel? existingPost;
  final bool showBackButton;
  final VoidCallback? onPostAdded;

  const AddPostScreen({
    super.key, 
    this.existingPost,
    this.showBackButton = true,
    this.onPostAdded,
  });''', content, flags=re.DOTALL)

# Find where _buildInputDecoration starts
# Remove everything from class _AddPostScreenState up to _buildInputDecoration
content = re.sub(r'class _AddPostScreenState extends State<AddPostScreen> \{.*?InputDecoration _buildInputDecoration\(\{', 
'''  InputDecoration _buildInputDecoration({''', content, flags=re.DOTALL)

# Insert the controller inside the build method
content = re.sub(r'@override\s*Widget build\(BuildContext context\) \{',
'''  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddPostController(
      existingPost: existingPost,
      onPostAdded: onPostAdded,
    ));''', content)

# Replace all variables and methods
replacements = {
    r'_formKey': r'controller.formKey',
    r'_titleController': r'controller.titleController',
    r'_rentController': r'controller.rentController',
    r'_addressController': r'controller.addressController',
    r'_phoneController': r'controller.phoneController',
    r'_seatDescController': r'controller.seatDescController',
    r'_pickedLocalImages': r'controller.pickedLocalImages',
    r'_bachelorType': r'controller.bachelorType.value',
    r'_preferredTenant': r'controller.preferredTenant.value',
    r'_selectedFacilities': r'controller.selectedFacilities',
    r'_allFacilities': r'controller.allFacilities',
    r'_selectedLocation': r'controller.selectedLocation.value',
    r'isEditing': r'controller.isEditing',
    r'widget\.showBackButton': r'showBackButton',
    r'widget\.existingPost': r'existingPost',
    r'_pickImagesFromGallery': r'controller.pickImagesFromGallery',
    r'_submit': r'controller.submit',
    r'setState\(\(\)\s*\{\s*controller\.selectedLocation\.value\s*=\s*picked;\s*\}\);': r'controller.selectedLocation.value = picked;',
    r'setState\(\(\)\s*\{\s*controller\.pickedLocalImages\.clear\(\);\s*\}\)': r'controller.pickedLocalImages.clear()',
    r'setState\(\(\)\s*\{\s*controller\.pickedLocalImages\.removeAt\(index\);\s*\}\);': r'controller.pickedLocalImages.removeAt(index);',
}

for k, v in replacements.items():
    content = re.sub(k, v, content)

# Wrap Obx for Facilities
content = content.replace('''                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: controller.allFacilities.map((facility) {''', 
'''                Obx(() => Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: controller.allFacilities.map((facility) {''')

content = content.replace('''                        setState(() {
                          if (selected) {
                            controller.selectedFacilities.add(facility);
                          } else {
                            controller.selectedFacilities.remove(facility);
                          }
                        });''', 
'''                        if (selected) {
                          controller.selectedFacilities.add(facility);
                        } else {
                          controller.selectedFacilities.remove(facility);
                        }''')

content = content.replace('''                    );
                  }).toList(),
                ),''', 
'''                    );
                  }).toList(),
                )),''')

# Wrap Obx for Photos
content = content.replace('''                if (controller.pickedLocalImages.isNotEmpty) ...[''',
'''                Obx(() {
                  if (controller.pickedLocalImages.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [''')

content = content.replace('''                ] else if (controller.isEditing &&
                    existingPost!.images.isNotEmpty) ...[''',
'''                    ]);
                  } else if (controller.isEditing && existingPost!.images.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [''')

content = content.replace('''                  ),
                ],
                SizedBox(height: 32.h),''',
'''                  )]);
                  }
                  return const SizedBox.shrink();
                }),
                SizedBox(height: 32.h),''')

# Fix gender and tenant radio methods
content = re.sub(r'Widget _buildGenderRadio\(String value, String label\) \{', 
                 r'Widget _buildGenderRadio(String value, String label, AddPostController controller) {', content)
content = content.replace('''      onTap: () {
        setState(() {
          controller.bachelorType.value = value;
        });
      },''',
      '''      onTap: () {
        controller.bachelorType.value = value;
      },''')
content = content.replace('''      child: Container(''', '''      child: Obx(() => Container(''')
content = content.replace('''            ),
          ],
        ),
      ),''', '''            ),
          ],
        ),
      )),''')

content = re.sub(r'Widget _buildTenantRadio\(String value, String label\) \{', 
                 r'Widget _buildTenantRadio(String value, String label, AddPostController controller) {', content)
content = content.replace('''      onTap: () {
        setState(() {
          controller.preferredTenant.value = value;
        });
      },''',
      '''      onTap: () {
        controller.preferredTenant.value = value;
      },''')

content = content.replace('''_buildGenderRadio('male', 'Male Only')''', '''_buildGenderRadio('male', 'Male Only', controller)''')
content = content.replace('''_buildGenderRadio('female', 'Female Only')''', '''_buildGenderRadio('female', 'Female Only', controller)''')
content = content.replace('''_buildGenderRadio('both', 'Any Bachelor')''', '''_buildGenderRadio('both', 'Any Bachelor', controller)''')

content = content.replace('''_buildTenantRadio('Student', 'Student')''', '''_buildTenantRadio('Student', 'Student', controller)''')
content = content.replace('''_buildTenantRadio('Job', 'Job')''', '''_buildTenantRadio('Job', 'Job', controller)''')
content = content.replace('''_buildTenantRadio(
                      'Student / Job holder',
                      'Student / Job holder',
                    )''', '''_buildTenantRadio(
                      'Student / Job holder',
                      'Student / Job holder', controller
                    )''')

with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)

print("Done")
