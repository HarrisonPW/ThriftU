import 'package:flutter/material.dart';
import 'api_service.dart';


class ChatProvider extends ChangeNotifier {
  final String token;
  final int contactUserId;  // For sending messages
  final String contactUserEmail;  // For filtering messages

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;

  ChatProvider({
    required this.token,
    required this.contactUserId,
    required this.contactUserEmail,
  }) {
    fetchMessages();
  }

  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMessages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch all messages
      final allMessages = await ApiService().fetchMessages(token);

      // Filter messages by email
      _messages = allMessages.where((message) {
        return (message['from_user_email'] == contactUserEmail || message['to_user_email'] == contactUserEmail);
      }).toList();
    } catch (e) {
      _errorMessage = 'Failed to load messages';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.isNotEmpty) {
      try {
        await ApiService().sendMessage(token, contactUserId, text);
        await fetchMessages();  // Refresh messages after sending
      } catch (e) {
        _errorMessage = 'Failed to send message';
        notifyListeners();
      }
    }
  }
}
