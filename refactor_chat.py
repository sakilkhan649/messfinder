import re
import os

filepath = r"d:\sakil\mess_finder\lib\features\chat\views\chat_screen.dart"

with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

# Change to StatelessWidget
content = re.sub(r'class ChatScreen extends StatefulWidget \{.*?\n\}', 
'''class ChatScreen extends StatelessWidget {
  final String chatRoomId;
  final String targetUserId;
  final String targetUserName;
  final String? targetUserPhoto;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserPhoto,
  });''', content, flags=re.DOTALL)

# Remove State class
content = re.sub(r'class _ChatScreenState extends State<ChatScreen> \{.*?@override\s*Widget build\(BuildContext context\) \{', 
'''  @override
  Widget build(BuildContext context) {
    final screenController = Get.put(ChatScreenController(chatRoomId), tag: chatRoomId);
    final _chatController = Get.find<ChatController>();''', content, flags=re.DOTALL)

content = content.replace('''_messageController''', '''screenController.messageController''')
content = content.replace('''_sendMessage()''', '''screenController.sendMessage(targetUserId)''')
content = content.replace('''_sendMessage''', '''() => screenController.sendMessage(targetUserId)''')

content = content.replace('''widget.chatRoomId''', '''chatRoomId''')
content = content.replace('''widget.targetUserId''', '''targetUserId''')
content = content.replace('''widget.targetUserName''', '''targetUserName''')
content = content.replace('''widget.targetUserPhoto''', '''targetUserPhoto''')


# Add ChatScreenController class at the end
controller_class = '''
class ChatScreenController extends GetxController {
  final String chatRoomId;
  final TextEditingController messageController = TextEditingController();
  final ChatController chatController = Get.find<ChatController>();

  ChatScreenController(this.chatRoomId);

  @override
  void onInit() {
    super.onInit();
    chatController.markMessagesAsRead(chatRoomId);
  }

  void sendMessage(String targetUserId) {
    final text = messageController.text;
    if (text.trim().isNotEmpty) {
      chatController.sendMessage(chatRoomId, text, targetUserId);
      messageController.clear();
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
'''

content += controller_class

with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)

print("Done")
