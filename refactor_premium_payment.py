import re
import os

filepath = r"d:\sakil\mess_finder\lib\core\widgets\premium_payment_dialog.dart"

with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

# Change to StatelessWidget
content = re.sub(r'class _PremiumPaymentSheet extends StatefulWidget \{.*?\n\}', 
'''class _PremiumPaymentSheet extends StatelessWidget {
  final UserModel user;
  final bool isLandlord;
  final Function(String trxId, String senderNumber)? onPaymentSubmitted;
  final VoidCallback? onSuccess;

  const _PremiumPaymentSheet({
    required this.user,
    required this.isLandlord,
    this.onPaymentSubmitted,
    this.onSuccess,
  });''', content, flags=re.DOTALL)

# Remove State class up to build
content = re.sub(r'class _PremiumPaymentSheetState extends State<_PremiumPaymentSheet> \{.*?(?=@override\s*Widget build\(BuildContext context\))', 
'''  ''', content, flags=re.DOTALL)

# Let's replace _getAdminNumber and _copyNumber inside build, wait no, they are outside build right now, and removed by my regex above.
content = content.replace('''  @override
  Widget build(BuildContext context) {''', 
'''  String _getAdminNumber(PaymentController paymentController) {
    final method = paymentController.selectedMethod.value;
    if (method == 'rocket') {
      return '018685691625';
    }
    return '01868569162';
  }

  void _copyNumber(String number) {
    Clipboard.setData(ClipboardData(text: number));
    ApiChecker.showSuccess('Copied number: $number', title: 'Copied');
  }

  @override
  Widget build(BuildContext context) {
    final screenController = Get.put(PremiumPaymentController());
    final paymentController = Get.find<PaymentController>();''')

# Replace properties in the class
content = content.replace('''widget.user''', '''user''')
content = content.replace('''widget.isLandlord''', '''isLandlord''')
content = content.replace('''widget.onPaymentSubmitted''', '''onPaymentSubmitted''')
content = content.replace('''widget.onSuccess''', '''onSuccess''')

content = content.replace('''_senderController''', '''screenController.senderController''')
content = content.replace('''_trxIdController''', '''screenController.trxIdController''')
content = content.replace('''_paymentController''', '''paymentController''')

content = content.replace('''_getAdminNumber()''', '''_getAdminNumber(paymentController)''')
content = content.replace('''_copyNumber(_getAdminNumber())''', '''_copyNumber(_getAdminNumber(paymentController))''')
content = content.replace('''onPressed: () => _copyNumber(adminNum),''', '''onPressed: () => _copyNumber(_getAdminNumber(paymentController)),''')

controller_class = '''
class PremiumPaymentController extends GetxController {
  final TextEditingController senderController = TextEditingController();
  final TextEditingController trxIdController = TextEditingController();

  @override
  void onClose() {
    senderController.dispose();
    trxIdController.dispose();
    super.onClose();
  }
}
'''

content += controller_class

with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)

print("Done")
