import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_page.dart';
import 'api_service.dart';
import 'chat_provider.dart';

class SearchUserPage extends StatefulWidget {
  final String token;

  const SearchUserPage({Key? key, required this.token}) : super(key: key);

  @override
  _SearchUserPageState createState() => _SearchUserPageState();
}

class _SearchUserPageState extends State<SearchUserPage> {
  final TextEditingController _emailController = TextEditingController();
  String? errorMessage;
  Map<String, dynamic>? searchedUser;

  Future<void> _searchUser() async {
    setState(() {
      errorMessage = null;
      searchedUser = null;
    });

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        errorMessage = "Please enter a valid email address.";
      });
      return;
    }

    try {
      final user = await ApiService.searchUser(widget.token, email);
      if (user != null) {
        setState(() {
          searchedUser = user;
        });
      } else {
        setState(() {
          errorMessage = "User not found.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "An error occurred while searching: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search User")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "User Email",
                hintText: "Enter email to search",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _searchUser,
              child: const Text("Search"),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (searchedUser != null) ...[
              const SizedBox(height: 16),
              ListTile(
                title: Text("User: ${searchedUser!['user_name']}"),
                subtitle: Text("Email: ${searchedUser!['email']}"),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider(
                          create: (_) => ChatProvider(
                            token: widget.token,
                            contactUserId: searchedUser!['user_id'],
                          ),
                          child: ChatPage(
                            userId: searchedUser!['user_id'],
                            token: widget.token,
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text("Start Chat"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
