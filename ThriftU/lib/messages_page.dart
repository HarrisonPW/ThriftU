import 'package:flutter/material.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: const Color(0xFFFFFFFF), // White background for the app bar
      ),
      body: Column(
        children: [
          // Your Story Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Story',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: Color(0xFFB0B0B0), // Grey color for subtitle
                  ),
                ),
                const SizedBox(height: 10),
                // User profiles in Your Story
                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: List.generate(4, (index) {
                      return Container(
                        width: 65,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: AssetImage('assets/images/user$index.png'), // Placeholder for profile image
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'User',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFB0B0B0), // Grey color for user name
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          const Divider(),
          // Message List
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: Text('U$index'), // Placeholder for user initials
                  ),
                  title: Text('User $index'),
                  subtitle: Text('Last message from User $index'),
                  trailing: Text('10:30 AM'), // Placeholder for message time
                  onTap: () {
                    // Navigate to a detailed chat view (optional)
                    // Navigator.pushNamed(context, '/chat', arguments: userId);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action for new message
        },
        child: const Icon(Icons.message),
      ),
    );
  }
}
