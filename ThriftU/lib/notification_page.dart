import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bottom_navigation_bar.dart';
import 'api_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _currentIndex = 3; // Set the index for Notifications
  List<int> userPostIds = [];
  List<Map<String, dynamic>> notifications = [];
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<String?> getToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error fetching token: $e');
      return null;
    }
  }

  Future<void> _fetchNotifications() async {
    final token = await getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is missing, please log in again')),
      );
      return;
    }

    try {
      final fetchedNotifications = await apiService.fetchNotifications(token, userPostIds);
      setState(() {
        notifications = fetchedNotifications;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching notifications: $e')),
      );
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    setState(() {
      notifications = notifications.map((notification) {
        if (notification['id'] == notificationId) {
          notification['is_read'] = true;
        }
        return notification;
      }).toList();
    });
  }

  void _deleteNotification(int notificationId) {
    setState(() {
      notifications = notifications.where((notification) => notification['id'] != notificationId).toList();
    });
  }

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
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: notifications.isEmpty
            ? const Center(
          child: Text('No notifications available.'),
        )
            : ListView.builder(
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
                      : Icons.reply,
                  color: notification['is_read'] ? Colors.grey : Colors.blueAccent,
                  size: 30,
                ),
                title: Text(
                  notification['content'],
                  style: TextStyle(
                    fontWeight: notification['is_read'] ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(notification['timestamp']),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteNotification(notification['id']),
                ),
                onTap: () => _markAsRead(notification['id']),
              ),
            );
          },
        ),
      ),
    );
  }
}
