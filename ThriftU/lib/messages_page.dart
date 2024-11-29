import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'search_user_page.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';
import 'chat_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  String? token;
  Future<List<Map<String, dynamic>>>? _chats;

  Future<void> _initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('auth_token');
    });

    if (token != null) {
      setState(() {
        _chats = ApiService.fetchMessages(token!);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              if (token != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchUserPage(token: token!),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: token == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
        future: _chats,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No messages found.'),
                  ElevatedButton(
                    onPressed: () {
                      if (token != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SearchUserPage(token: token!),
                          ),
                        );
                      }
                    },
                    child: const Text('Start a Chat'),
                  ),
                ],
              ),
            );
          }

          final messages = snapshot.data!;
          // Group messages by user
          final Map<int, Map<String, dynamic>> groupedMessages = {};
          for (var message in messages) {
            final int? fromUserId = message['from_user_id'];
            final int? toUserId = message['to_user_id'];

            // Determine the userId to group messages by
            final int userId = (fromUserId == message['to_user_id'])
                ? fromUserId!
                : (toUserId != null ? toUserId : fromUserId!);

            // Add to grouped messages if not already added
            if (!groupedMessages.containsKey(userId)) {
              groupedMessages[userId] = message; // Use the first message from/to this user
            }
          }

          final uniqueChats = groupedMessages.values.toList();

          return ListView.builder(
            itemCount: uniqueChats.length,
            itemBuilder: (context, index) {
              final chat = uniqueChats[index];
              final int chatUserId = chat['to_user_id'] != chat['from_user_id']
                  ? (chat['to_user_id'] ?? chat['from_user_id'])
                  : chat['from_user_id'];
              final email = chat['to_user_email'] ?? chat['from_user_email'] ?? 'Unknown';

              return ListTile(
                title: Text('Chat with $email'),
                subtitle: Text(chat['text'] ?? 'No message'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => ChatProvider(
                          token: token!,
                          contactUserId: chatUserId,
                        ),
                        child: ChatPage(
                          userId: chatUserId,
                          token: token!,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
