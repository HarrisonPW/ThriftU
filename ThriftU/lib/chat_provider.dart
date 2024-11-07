import 'package:flutter/material.dart';
import 'api_service.dart';

class ChatProvider extends ChangeNotifier {
  final String token;
  final int userId;
  final String postId; // Add postId as a required parameter
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;

  ChatProvider({required this.token, required this.userId, required this.postId}) {
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
      _messages = await ApiService().fetchMessages(token);
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
        // Pass postId along with other required parameters
        await ApiService().sendMessage(token, userId, postId, text);
        await fetchMessages(); // Refresh messages after sending
      } catch (e) {
        _errorMessage = 'Failed to send message';
        notifyListeners();
      }
    }
  }
}
