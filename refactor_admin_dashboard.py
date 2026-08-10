import re

filepath = r"d:\sakil\mess_finder\lib\features\admin\views\admin_dashboard_screen.dart"

with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

# Change to StatelessWidget
content = re.sub(r'class AdminDashboardScreen extends StatefulWidget \{.*?\n\}', 
'''class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});''', content, flags=re.DOTALL)

# Remove State class
content = re.sub(r'class _AdminDashboardScreenState extends State<AdminDashboardScreen> \{.*?@override\s*void initState\(\) \{.*?\}\s*@override\s*Widget build\(BuildContext context\) \{', 
'''  @override
  Widget build(BuildContext context) {
    final _adminController = Get.find<AdminController>();''', content, flags=re.DOTALL)


content = content.replace('''_buildAppBar() {''', '''_buildAppBar(AdminController _adminController) {''')
content = content.replace('''appBar: _buildAppBar(),''', '''appBar: _buildAppBar(_adminController),''')

content = content.replace('''_buildBottomNav() {''', '''_buildBottomNav(AdminController _adminController) {''')
content = content.replace('''bottomNavigationBar: _buildBottomNav(),''', '''bottomNavigationBar: _buildBottomNav(_adminController),''')

with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)

print("Done")
