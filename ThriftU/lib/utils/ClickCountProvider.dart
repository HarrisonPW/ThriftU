import 'package:flutter/material.dart';

class ClickCountProvider with ChangeNotifier {
  Map<String, int> _clickCounts = {};

  Map<String, int> get clickCounts => _clickCounts;

  void incrementClickCount(String index) {
    _clickCounts[index] = (_clickCounts[index] ?? 0) + 1;
    notifyListeners();
    print("#" * 20);
    _clickCounts.forEach((key, value) {
      print('INFO: BUTTON: $key, Click Count: $value');
    });
    print("#" * 20);
  }
}
