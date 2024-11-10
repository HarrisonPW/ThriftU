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
  String? token;
  Map<String, dynamic>? _searchedUser;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  Future<List<Map<String, dynamic>>>? _chats;

  Future<void> getTokenAndUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('auth_token');
    });
    if (token != null) {
      _fetchChats();
    } else {
      setState(() {
        _errorMessage = 'Token is missing. Please log in again.';
      });
    }
  }

  void _fetchChats() {
    setState(() {
      _chats = ApiService().fetchMessages(token!);
    });
  }

  @override
  void initState() {
    super.initState();
    getTokenAndUserId();
  }

  Future<void> _searchUser() async {
    final email = _searchController.text.trim();
    if (email.isEmpty || token == null) {
      setState(() {
        _errorMessage = 'Please enter an email and ensure you are logged in.';
      });
      return;
    }

    try {
      final user = await ApiService().searchUser(token!, email);
      setState(() {
        _searchedUser = user;
        _errorMessage = user == null ? 'User not found.' : null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by email',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchUser,
                ),
              ),
              onSubmitted: (_) => _searchUser(),
            ),
          ),
        ),
      ),
      body: _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : Column(
        children: [
          if (_searchedUser != null) ...[
            ListTile(
              title: Text(_searchedUser!['user_name'] ?? 'User'),
              subtitle: Text('User ID: ${_searchedUser!['user_id']}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      userId: _searchedUser!['user_id'],
                      contactUserEmail: _searchController.text.trim(),
                      token: token!,
                    ),
                  ),
                );
              },
            ),
            const Divider(),
          ],
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _chats,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No messages found. Start browsing to chat.'));
                } else {
                  return ListView(
                    children: snapshot.data!.map((chat) {
                      final contactId = chat['from_user_id'] == _searchedUser?['user_id']
                          ? chat['to_user_id']
                          : chat['from_user_id'];
                      final contactEmail = chat['from_user_email'];

                      return ListTile(
                        title: Text('Chat with $contactEmail'),
                        subtitle: Text(chat['text'] ?? 'No message'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                userId: contactId,
                                contactUserEmail: contactEmail,
                                token: token!,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
