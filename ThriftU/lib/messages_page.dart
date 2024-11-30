import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'search_user_page.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';
import 'chat_page.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'search_user_page.dart';
import 'chat_page.dart';
import 'api_service.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  String? token;
  int? currentUserId;
  Future<List<Map<String, dynamic>>>? _chats;

  Future<void> _initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('auth_token');
      currentUserId = prefs.getInt('user_id'); // Assuming the user ID is stored here
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
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No messages found. Start browsing and chatting!',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          // Group messages by "to user ID"
          final groupedMessages = <int, Map<String, dynamic>>{};
          for (var message in snapshot.data!) {
            final toUserId = message['to_user_id'];
            final fromUserId = message['from_user_id'];

            // Ensure the chat displays the "other user"
            final otherUserId = currentUserId == fromUserId ? toUserId : fromUserId;

            if (!groupedMessages.containsKey(otherUserId)) {
              groupedMessages[otherUserId] = message;
            }
          }

          final uniqueChats = groupedMessages.values.toList();

          return ListView.builder(
            itemCount: uniqueChats.length,
            itemBuilder: (context, index) {
              final message = uniqueChats[index];
              final toUserId = message['to_user_id'];
              final fromUserId = message['from_user_id'];

              // Determine the other user's ID and email
              final otherUserId = currentUserId == fromUserId ? toUserId : fromUserId;
              final otherUserEmail = currentUserId == fromUserId
                  ? message['to_user_email']
                  : message['from_user_email'];

              return ListTile(
                title: Text('Chat with $toUserId'),
                subtitle: Text(message['text'] ?? 'No message'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => ChatProvider(contactUserId: toUserId, token: token!), // Pass required values
                        child: ChatPage(
                          userId: toUserId,
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
