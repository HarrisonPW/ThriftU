import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'api_service.dart';
import 'item_details_page.dart';

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
  final ApiService apiService = ApiService();
  Map<int, List<String>> postImages = {};
  List<dynamic> userPosts = [];

  @override
  void initState() {
    super.initState();
    _fetchUserPosts();
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

  Future<void> _fetchUserPosts() async {
    final token = await getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is missing, please log in again')),
      );
      return;
    }

    try {
      // Fetch user posts
      final posts = await apiService.getUserPosts(token);
      setState(() {
        userPosts = posts.where((post) => post['post_type'] == 'Furniture' || post['post_type'] == 'Clothes' || post['post_type'] == 'Kitchenware').toList();;
      });

      // Fetch associated image URLs for each post
      for (var post in posts) {
        if (post['files'] != null && post['files'].isNotEmpty) {
          List<String> imageUrls = [];
          for (var fileId in post['files']) {
            print("file id: $fileId");
            final imageUrl = await apiService.getFileUrl(fileId, token);
            imageUrls.add(imageUrl);
          }
          postImages[post['post_id']] = imageUrls;
        } else {
          postImages[post['post_id']] = ['https://via.placeholder.com/140'];
        }
      }

      setState(() {}); // Trigger UI update

    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching posts: $error')),
      );
    }
  }

  Future<void> _navigateToDetails(int postId) async {
    final token = await getToken();
    if (token != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ItemDetailsPage(
            postId: postId,
            token: token,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is missing, please log in again')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    final token = await getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is missing, please log in again')),
      );
      return;
    }

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);  // Store the selected image locally
      });

      // Upload the image to the backend
      try {
        await apiService.uploadFile(_profileImage!, token);
        print('Profile image uploaded successfully');
      } catch (e) {
        print('Error uploading profile image: $e');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // Example data (replace with actual values from API or backend)
    final String userName = "Your Name";
    final int followersCount = 120;
    final int followingCount = 75;

    final List<Map<String, String>> likes = [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('@$userName', style: TextStyle(color: Colors.black)),
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
            InkWell(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : AssetImage('assets/images/profile.jpeg') as ImageProvider,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 15,
                    child: Icon(Icons.edit, size: 20, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text('$followersCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('Followers'),
                  ],
                ),
                const SizedBox(width: 50),
                Column(
                  children: [
                    Text('$followingCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('Following'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showListings = true;
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
                          '${userPosts.length}',
                          style: const TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Text('Listings', style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showListings = false;
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
                          '${likes.length}',
                          style: const TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Text('Likes', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Listings or Likes based on toggle
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchUserPosts,
                child: _showListings && userPosts.isEmpty || !_showListings && likes.isEmpty
                    ? Center(
                      child: Text(
                        "Nothing here, go find something you like!",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _showListings ? userPosts.length : likes.length,
                      itemBuilder: (context, index) {
                        final data = _showListings ? userPosts[index] : likes[index];
                        final postID = _showListings ? userPosts[index]['post_id'] : likes[index];
                        final imageUrls = _showListings ? postImages[data['post_id']] ?? [] : [];
                        final displayImage = imageUrls.isNotEmpty ? imageUrls[0] : 'https://via.placeholder.com/140';

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                displayImage,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              data["title"] ?? 'Untitled',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: Text(
                              '\$${data["price"]?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onTap: () => _navigateToDetails(postID),
                          ),
                        );
                      },
                    ),
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
