import re
import os

filepath = r"d:\sakil\mess_finder\lib\features\chat\views\chat_screen.dart"

with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

# _buildMessageInput
content = content.replace('''Widget _buildMessageInput(
      Color rolePrimaryColor, LinearGradient rolePrimaryGradient) {''', 
'''Widget _buildMessageInput(
      Color rolePrimaryColor, LinearGradient rolePrimaryGradient, ChatScreenController screenController, ChatController _chatController) {''')
content = content.replace('''_buildMessageInput(rolePrimaryColor, rolePrimaryGradient),''', 
'''_buildMessageInput(rolePrimaryColor, rolePrimaryGradient, screenController, _chatController),''')

# _buildMessageBubble
content = content.replace('''Widget _buildMessageBubble(
      MessageModel message, bool isMe, Color rolePrimaryColor) {''', 
'''Widget _buildMessageBubble(
      MessageModel message, bool isMe, Color rolePrimaryColor, ChatController _chatController) {''')
content = content.replace('''_buildMessageBubble(message, isMe, rolePrimaryColor)''', 
'''_buildMessageBubble(message, isMe, rolePrimaryColor, _chatController)''')

# _showImagePreview
content = content.replace('''void _showImagePreview(BuildContext context, String imageUrl) {''', 
'''void _showImagePreview(BuildContext context, String imageUrl, ChatController _chatController) {''')
content = content.replace('''onTap: () => _showImagePreview(context, message.imageUrl!),''', 
'''onTap: () => _showImagePreview(context, message.imageUrl!, _chatController),''')

with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)

print("Done")
