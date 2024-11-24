import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';

class _MessageInputField extends StatefulWidget {
  @override
  _MessageInputFieldState createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<_MessageInputField> {
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage(ChatProvider chatProvider) {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      chatProvider.sendMessage(text);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _sendMessage(chatProvider),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}


class ChatPage extends StatelessWidget {
  final int userId;  // Contact's user ID for sending messages
  final String contactUserEmail;  // Email for filtering messages
  final String token;

  const ChatPage({
    Key? key,
    required this.userId,
    required this.contactUserEmail,
    required this.token,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(
        token: token,
        contactUserId: userId,
        contactUserEmail: contactUserEmail,  // Pass email to ChatProvider
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chat with $contactUserEmail'),
        ),
        body: Column(
          children: [
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, _) {
                  if (chatProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (chatProvider.errorMessage != null) {
                    return Center(child: Text(chatProvider.errorMessage!));
                  } else if (chatProvider.messages.isEmpty) {
                    return const Center(child: Text('No messages.'));
                  } else {
                    return ListView(
                      reverse: true, // This will make the ListView start from the bottom
                      children: chatProvider.messages.reversed.map((message) {
                        return ListTile(
                          title: Text(message['text']),
                          subtitle: Text(
                            message['from_user_email'] == chatProvider.contactUserEmail ? chatProvider.contactUserEmail : 'You',
                          ),
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ),
            _MessageInputField(),  // Message input at the bottom
          ],
        ),
      ),
    );
  }
}
