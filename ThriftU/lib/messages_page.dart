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
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _chats;
  Map<String, dynamic>? _searchedUser;
  String? token;
  String? _errorMessage;

  Future<void> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('auth_token');
    });
  }

  @override
  void initState() {
    super.initState();
    getToken().then((_) {
      if (token != null) {
        setState(() {
          _chats = ApiService().fetchMessages(token!);
        });
      }
    });
  }

  Future<void> _searchUser() async {
    final email = _searchController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an email to search';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _searchedUser = null;
    });

    try {
      final user = await ApiService().searchUser(token!, email);
      setState(() {
        _searchedUser = user;
        if (_searchedUser == null) {
          _errorMessage = 'User not found';
        }
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
      body: Column(
        children: [
          if (_errorMessage != null) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ] else if (_searchedUser != null) ...[
            ListTile(
              title: Text(_searchedUser!['user_name'] ?? 'User'),
              subtitle: Text('User ID: ${_searchedUser!['user_id']}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      userId: _searchedUser!['user_id'],
                      userName: _searchedUser!['user_name'] ?? 'User',
                      token: token!,
                      postId: '',
                    ),
                  ),
                );
              },
            ),
            const Divider(),
          ],
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        userId: chat['user_id'],
                        userName: chat['user_name'],
                        token: token!,
                        postId: '',
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        }
      },
    );
  }
}
