import 'package:flutter/material.dart';
import 'bottom_navigation_bar.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _currentIndex = 3; // Set the index for Notifications

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/marketplace');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/plaza');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/post');
        break;
      case 3:
      // Already on Notifications page
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  // Sample notifications (replace with real data from backend)
  final List<Map<String, String>> notifications = [
    {
      'type': 'Message',
      'content': 'You have a new message from John.',
      'time': '2 min ago',
    },
    {
      'type': 'Comment',
      'content': 'Alice commented on your post.',
      'time': '10 min ago',
    },
    {
      'type': 'Message',
      'content': 'You have a new message from Sarah.',
      'time': '1 hr ago',
    },
    {
      'type': 'Comment',
      'content': 'David replied to your comment.',
      'time': '3 hrs ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: Icon(
                notification['type'] == 'Message'
                    ? Icons.message
                    : Icons.comment,
                color: Colors.blueAccent,
                size: 30,
              ),
              title: Text(
                notification['content']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(notification['time']!),
            ),
          );
        },
      ),
    );
  }
}
