import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemTapped;

  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Marketplace'),
        BottomNavigationBarItem(icon: Icon(Icons.apartment), label: 'Plaza'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle, size: 35), label: 'Post'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: currentIndex,
      onTap: onItemTapped,
      selectedItemColor: const Color(0xFF8EACCD),
      unselectedItemColor: Colors.grey,// Theme color
    );
  }
}
