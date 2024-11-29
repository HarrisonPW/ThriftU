import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';

class ChatPage extends StatelessWidget {
  final int userId;
  final String token;

  const ChatPage({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create a TextEditingController to manage input text
    final TextEditingController _messageController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with User $userId'),
      ),
      body: Column(
        children: [
          // Message List
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                return ListView.builder(
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    final isSentToUser = message['to_user_id'] == userId; // Check if the message was sent by the user
                    return ListTile(
                      title: Text(
                        message['text'], // Display the message text
                        textAlign: isSentToUser ? TextAlign.end : TextAlign.start,
                      ),
                      subtitle: Text(isSentToUser ? 'You' : 'Them'),
                    );
                  },
                );
              },
            ),
          ),
          // Message Input Field and Send Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(hintText: 'Type a message'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () {
                  final text = _messageController.text.trim();
                  if (text.isNotEmpty) {
                    final chatProvider = context.read<ChatProvider>();
                    chatProvider.sendMessage(text); // Send the input text
                    _messageController.clear(); // Clear the input field after sending
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
