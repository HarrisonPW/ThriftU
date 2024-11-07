import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'chat_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  late Future<List<Map<String, dynamic>>> _chats;
  String? token;

  Future<void> getToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        token = prefs.getString('auth_token');
      });
    } catch (e) {
      //
    }
  }

  @override
  void initState() {
    super.initState();
    getToken().then((_) {
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token is missing, please log in again')),
        );
      } else {
        setState(() {
          _chats = ApiService().fetchMessages(token!);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _chats,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No messages found.'));
        } else {
          return ListView(
            children: snapshot.data!.map((chat) {
              return ListTile(
                title: Text(chat['user_name']), // Adjust according to API response
                subtitle: Text(chat['last_message']),
                onTap: () {
                  if (token != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          userId: chat['user_id'],
                          userName: chat['user_name'],
                          token: token!,
                        ),
                      ),
                    );
                  }
                },
              );
            }).toList(),
          );
        }
      },
    );
  }
}
