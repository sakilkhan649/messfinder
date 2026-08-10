import re
import os

filepath = r"d:\sakil\mess_finder\lib\features\home\views\user_home_screen.dart"

with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

# Change to StatelessWidget
content = re.sub(r'class UserHomeScreen extends StatefulWidget \{.*?\n\}', 
'''import 'package:get/get.dart';
class UserHomeScreen extends StatelessWidget {
  final UserModel user;

  const UserHomeScreen({super.key, required this.user});''', content, flags=re.DOTALL)

# Remove State class
content = re.sub(r'class _UserHomeScreenState extends State<UserHomeScreen> \{.*?@override\s*Widget build\(BuildContext context\) \{', 
'''  @override
  Widget build(BuildContext context) {
    final RxInt currentIndex = 0.obs;
    final RxBool isBottomNavVisible = true.obs;''', content, flags=re.DOTALL)

content = content.replace('''_currentIndex''', '''currentIndex.value''')
content = content.replace('''widget.user''', '''user''')
content = content.replace('''setState(() {
            currentIndex.value = 0;
          });''', '''currentIndex.value = 0;''')
content = content.replace('''if (!_isBottomNavVisible) setState(() => _isBottomNavVisible = true);''', '''if (!isBottomNavVisible.value) isBottomNavVisible.value = true;''')
content = content.replace('''if (_isBottomNavVisible) setState(() => _isBottomNavVisible = false);''', '''if (isBottomNavVisible.value) isBottomNavVisible.value = false;''')
content = content.replace('''_isBottomNavVisible''', '''isBottomNavVisible.value''')

content = content.replace('''IndexedStack(index: currentIndex.value, children: screens)''', '''Obx(() => IndexedStack(index: currentIndex.value, children: screens))''')

# Wrap AnimatedSlide with Obx
content = content.replace('''            child: AnimatedSlide(''', '''            child: Obx(() => AnimatedSlide(''')

# Fix AnimatedSlide closing parenthesis
content = content.replace('''                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }''', '''                  ),
                ],
              ),
            )),
          ),
        ],
      ),
    );
  }''')

# Fix Floating Action Button onTap
content = content.replace('''onTap: () => setState(() => currentIndex.value = 2),''', '''onTap: () => currentIndex.value = 2,''')


content = re.sub(r'Widget _buildNavItem\(\{.*?\}\) \{.*?return GestureDetector\(',
'''  Widget _buildNavItem({
    required int index,
    required RxInt currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () => currentIndex.value = index,
      behavior: HitTestBehavior.opaque,
      child: Obx(() {
        final isSelected = currentIndex.value == index;
        return SizedBox(''', content, flags=re.DOTALL)


content = content.replace('''              ),
            ),
          ],
        ),
      ),
    );
  }''', '''              ),
            ),
          ],
        ),
      );
      }),
    );
  }''')

content = content.replace('''_buildNavItem(
                                    index: 0,
                                    icon: Icons.home_outlined,
                                    activeIcon: Icons.home_rounded,
                                    activeColor: primaryEmerald,
                                  ),''',
                                  '''_buildNavItem(
                                    index: 0,
                                    currentIndex: currentIndex,
                                    icon: Icons.home_outlined,
                                    activeIcon: Icons.home_rounded,
                                    activeColor: primaryEmerald,
                                  ),''')
content = content.replace('''_buildNavItem(
                                    index: 1,
                                    icon: Icons.location_on_outlined,
                                    activeIcon: Icons.location_on_rounded,
                                    activeColor: primaryEmerald,
                                  ),''',
                                  '''_buildNavItem(
                                    index: 1,
                                    currentIndex: currentIndex,
                                    icon: Icons.location_on_outlined,
                                    activeIcon: Icons.location_on_rounded,
                                    activeColor: primaryEmerald,
                                  ),''')
content = content.replace('''_buildNavItem(
                                    index: 3,
                                    icon: Icons.chat_bubble_outline_rounded,
                                    activeIcon: Icons.chat_bubble_rounded,
                                    activeColor: primaryEmerald,
                                  ),''',
                                  '''_buildNavItem(
                                    index: 3,
                                    currentIndex: currentIndex,
                                    icon: Icons.chat_bubble_outline_rounded,
                                    activeIcon: Icons.chat_bubble_rounded,
                                    activeColor: primaryEmerald,
                                  ),''')
content = content.replace('''_buildNavItem(
                                    index: 4,
                                    icon: Icons.person_outline_rounded,
                                    activeIcon: Icons.person_rounded,
                                    activeColor: primaryEmerald,
                                  ),''',
                                  '''_buildNavItem(
                                    index: 4,
                                    currentIndex: currentIndex,
                                    icon: Icons.person_outline_rounded,
                                    activeIcon: Icons.person_rounded,
                                    activeColor: primaryEmerald,
                                  ),''')


with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)

print("Done")
