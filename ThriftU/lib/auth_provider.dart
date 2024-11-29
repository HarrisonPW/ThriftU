import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userId;

  String? get token => _token;
  String? get userId => _userId;

  bool get isLoggedIn => _token != null;

  void setToken(String token, String userId) {
    _token = token;
    _userId = userId;
    notifyListeners();
  }

  void clearToken() {
    _token = null;
    _userId = null;
    notifyListeners();
  }
}
