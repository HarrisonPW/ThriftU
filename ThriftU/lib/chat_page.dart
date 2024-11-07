import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';

class ChatPage extends StatelessWidget {
  final int userId;
  final String userName;
  final String token;
  final String postId;

  const ChatPage({Key? key, required this.userId, required this.userName, required this.token, required this.postId,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(token: token, userId: userId, postId: postId),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chat with $userName'),
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
                      children: chatProvider.messages.map((message) {
                        return ListTile(
                          title: Text(message['text']),
                          subtitle: Text(message['sender_name']), // Adjust based on response
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ),
            _MessageInputField(),
          ],
        ),
      ),
    );
  }
}

class _MessageInputField extends StatefulWidget {
  @override
  State<_MessageInputField> createState() => _MessageInputFieldState();
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
}
