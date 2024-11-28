import 'package:flutter/material.dart';
import 'api_service.dart';

class ChatProvider extends ChangeNotifier {
  final String token;
  final int contactUserId;
  List<Map<String, dynamic>> _messages = [];

  List<Map<String, dynamic>> get messages => _messages;

  ChatProvider({required this.token, required this.contactUserId}) {
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    try {
      final allMessages = await ApiService.fetchMessages(token!);
      print("Fetched messages: $allMessages");

      // Filter messages based on the contactUserId
      _messages = allMessages.where((message) {
        final fromUserId = message['from_user_id'];
        final toUserId = message['to_user_id'];

        // Include messages where the contact is either the sender or receiver
        return (fromUserId == contactUserId || toUserId == contactUserId);
      }).toList();

      // Sort messages by timestamp to ensure correct order
      _messages.sort((a, b) => DateTime.parse(a['create_time']).compareTo(DateTime.parse(b['create_time'])));

      notifyListeners();
    } catch (e) {
      print("Failed to fetch messages: $e");
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.isNotEmpty) {
      try {
        await ApiService.sendMessage(token, contactUserId, text);
        await fetchMessages(); // Refresh messages after sending
      } catch (e) {
        print("Failed to send message: $e");
      }
    } else {
      print("Invalid input: token, contactUserId, or text is null");
    }
  }
}
