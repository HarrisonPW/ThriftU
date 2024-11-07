import 'package:flutter/material.dart';
import 'api_service.dart';

class ChatPage extends StatefulWidget {
  final String userId;
  final String userName;
  final String token;

  const ChatPage({Key? key, required this.userId, required this.userName, required this.token}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Future<List<Map<String, dynamic>>> _messages;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  void _fetchMessages() {
    setState(() {
      _messages = ApiService().fetchMessages(widget.token);
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text;
    if (text.isNotEmpty) {
      await ApiService().sendMessage(widget.token, widget.userId, '', text);
      _messageController.clear();
      _fetchMessages(); // Refresh messages after sending
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.userName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _messages,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No messages.'));
                } else {
                  return ListView(
                    children: snapshot.data!.map((message) {
                      return ListTile(
                        title: Text(message['text']),
                        subtitle: Text(message['sender_name']),
                      );
                    }).toList(),
                  );
                }
              },
            ),
          ),
          Padding(
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
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
