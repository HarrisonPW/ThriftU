import 'package:flutter/material.dart';
import 'bottom_navigation_bar.dart';

class PlazaPage extends StatefulWidget {
  const PlazaPage({Key? key}) : super(key: key);

  @override
  State<PlazaPage> createState() => _PlazaPageState();
}

class _PlazaPageState extends State<PlazaPage> {
  int _currentIndex = 1; // Set current index to Plaza

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index; // Update the current index
    });

    // Navigate to the appropriate page based on the tapped index
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/marketplace');
        break;
      case 1:
      // Plaza Page (already here)
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/post');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/notifications');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plaza'),
        backgroundColor: const Color(0xFFFFFF), // Set AppBar color
      ),
      body: Center(
        child: const Text(
          'Welcome to the Plaza!',
          style: TextStyle(fontSize: 24),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
