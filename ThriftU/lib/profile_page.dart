import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 4; // Set current index to Profile
  File? _profileImage; // To store the selected profile image
  final ImagePicker _picker = ImagePicker();
  bool _showListings = true;

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
        Navigator.pushReplacementNamed(context, '/plaza');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/post');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/notifications');
        break;
      case 4:
      // Stay on the Profile Page
        break;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Example data (replace with actual values from API or backend)
    final String userName = "Your Name";
    final int followersCount = 120;
    final int followingCount = 75;
    // final List<String> listings = ["Item 1", "Item 2", "Item 3"];
    final List<Map<String, String>> listings = [
      {"image": "assets/images/chair.jpeg", "title": "Office chair", "price": "\$10"}
    ];

    final List<Map<String, String>> likes = [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('@your name', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile picture, name, location
            InkWell(
              onTap: _pickImage, // Pick image on tap
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!) // Display selected image
                    : AssetImage('assets/images/profile.jpg') as ImageProvider, // Default image
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 15,
                    child: Icon(
                      Icons.edit,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Followers and Following counts
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      '$followersCount',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Followers'),
                  ],
                ),
                const SizedBox(width: 50),
                Column(
                  children: [
                    Text(
                      '$followingCount',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Following'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Leave the area below listing blank as requested
            // Toggle Buttons for Listings and Likes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showListings = true; // Show listings
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    decoration: BoxDecoration(
                      color: _showListings ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '1',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Listings',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showListings = false; // Show likes
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    decoration: BoxDecoration(
                      color: !_showListings ? Colors.green.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '0',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Likes',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // User Listings or Likes based on the selected toggle
            Expanded(
              child: _showListings && listings.isEmpty || !_showListings && likes.isEmpty
                  ? Center(
                child: Text(
                  "Nothing here, go find something you like!",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: _showListings ? listings.length : likes.length,
                itemBuilder: (context, index) {
                  final data = _showListings ? listings[index] : likes[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          data["image"]!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        data["title"]!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        data["price"]!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Marketplace'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Plaza'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Post'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
