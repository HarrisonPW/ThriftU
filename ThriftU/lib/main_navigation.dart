import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thriftu/utils/ClickCountProvider.dart';
import 'plaza_page.dart';
import 'post.dart';
import 'profile_page.dart';
import 'bottom_navigation_bar.dart';
import 'marketplace_page.dart';
import 'notification_page.dart'; // Import your CustomBottomNavigationBar

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0; // Default to the Marketplace page

  final List<Widget> _pages = [
    MarketplacePage(),
    PlazaPage(),
    PostPage(),
    NotificationPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index; // Update index to switch pages
      switch (index) {
        case 0:
          Provider.of<ClickCountProvider>(context, listen: false)
              .incrementClickCount('marketplace');
          break;
        case 1:
          Provider.of<ClickCountProvider>(context, listen: false)
              .incrementClickCount('plaza');
          break;
        case 2:
          Provider.of<ClickCountProvider>(context, listen: false)
              .incrementClickCount('post');
          break;
        case 3:
          Provider.of<ClickCountProvider>(context, listen: false)
              .incrementClickCount('notifications');
          break;
        case 4:
          Provider.of<ClickCountProvider>(context, listen: false)
              .incrementClickCount('profile');
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
