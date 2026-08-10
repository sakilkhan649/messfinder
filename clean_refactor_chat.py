import re

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
  });

  ChatScreenController get _screenController => Get.find<ChatScreenController>(tag: chatRoomId);
  ChatController get _chatController => Get.find<ChatController>();
  TextEditingController get _messageController => _screenController.messageController;

  void _sendMessage() {
    _screenController.sendMessage(targetUserId);
  }
''', content, flags=re.DOTALL)

# Remove State class declaration and merge it into ChatScreen
content = re.sub(r'class _ChatScreenState extends State<ChatScreen> \{.*?(?=@override\s*Widget build\(BuildContext context\))', 
'''  ''', content, flags=re.DOTALL)

# Now we need to fix widget. properties inside the old state methods
content = content.replace('''widget.chatRoomId''', '''chatRoomId''')
content = content.replace('''widget.targetUserId''', '''targetUserId''')
content = content.replace('''widget.targetUserName''', '''targetUserName''')
content = content.replace('''widget.targetUserPhoto''', '''targetUserPhoto''')

# Inside build method, add the Get.put for the controller
content = re.sub(r'(@override\s*Widget build\(BuildContext context\) \{)', 
r'\1\n    Get.put(ChatScreenController(chatRoomId), tag: chatRoomId);', content)


controller_class = '''
class ChatScreenController extends GetxController {
  final String chatRoomId;
  late final ChatController chatController;
  final TextEditingController messageController = TextEditingController();

  ChatScreenController(this.chatRoomId) {
    chatController = Get.find<ChatController>();
  }

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
