import re
import os

filepath = r"d:\sakil\mess_finder\lib\features\payment\views\payment_screen.dart"

with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

# Change to StatelessWidget
content = re.sub(r'class PaymentScreen extends StatefulWidget \{.*?\n\}', 
'''class PaymentScreen extends StatelessWidget {
  final UserModel user;

  const PaymentScreen({super.key, required this.user});''', content, flags=re.DOTALL)

# Find where _copyToClipboard starts
# Remove everything from class _PaymentScreenState up to _copyToClipboard
content = re.sub(r'class _PaymentScreenState extends State<PaymentScreen> \{.*?void _copyToClipboard', 
'''  void _copyToClipboard''', content, flags=re.DOTALL)

# Replace variables and methods
content = content.replace('''_senderNumberController''', '''controller.senderNumberController''')
content = content.replace('''_trxIdController''', '''controller.trxIdController''')
content = content.replace('''_paymentController''', '''controller''')
content = content.replace('''widget.user''', '''user''')

# Update build signature
content = re.sub(r'@override\s*Widget build\(BuildContext context\) \{', 
'''  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PaymentController>();''', content)


with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)

print("Done")
