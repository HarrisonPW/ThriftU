import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
//import 'package:firebase_analytics/firebase_analytics.dart';

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
  List<dynamic> likedPosts = [];
  Map<int, List<String>> likedPostImages = {};
  String? userName;
  String? userEmail;
  String? avatarUrl;
  int _followingCount = 0;
  int _followerCount = 0;
  // final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  // Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchUserPosts();
    _fetchLikedPosts();
    _fetchFollowingCount();
    _fetchFollowerCount();
    //_startTimer();
  }

  @override
  void dispose() {
    super.dispose();
   // _stopTimer();
  }

  // Future<void> _startTimer() async {
  //   _stopwatch.start();
  // }
  //
  // Future<void> _stopTimer() async {
  //   _stopwatch.stop();
  //   final timeSpent = _stopwatch.elapsedMilliseconds;
  //   // Log time spent on the page
  //   await _analytics.logEvent(
  //     name: 'page_view',
  //     parameters: {
  //       'page_name': 'Marketplace page',
  //       'time_spent': timeSpent,
  //     },
  //   );
  // }

  Future<String?> getToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error fetching token: $e');
      return null;
    }
  }

  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchUserProfile(),
      _fetchUserPosts(),
      _fetchLikedPosts(),
      _fetchFollowingCount(),
      _fetchFollowerCount(),
    ]);
  }

  Future<void> _fetchLikedPosts() async {
    final token = await getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is missing, please log in again')),
      );
      return;
    }

    try {
      final posts = await apiService.getUserLikedPosts(token);
      setState(() {
        likedPosts = posts;
      });

      for (var post in posts) {
        if (post['files'] != null && post['files'].isNotEmpty) {
          List<String> imageUrls = [];
          for (var fileId in post['files']) {
            final imageUrl = await apiService.getFileUrl(fileId, token);
            imageUrls.add(imageUrl);
          }
          likedPostImages[post['post_id']] = imageUrls;
        } else {
          likedPostImages[post['post_id']] = ['https://via.placeholder.com/140'];
        }
      }

      setState(() {});
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching liked posts: $error')),
      );
    }
  }

  Future<void> _fetchUserProfile() async {
    final token = await getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is missing, please log in again')),
      );
      return;
    }

    try {
      final profile = await apiService.getUserProfile(token);
      String? fetchedAvatarUrl;
      if (profile['avatar_file_id'] != null) {
        fetchedAvatarUrl = await apiService.getFileUrl(profile['avatar_file_id'], token);
      }

      setState(() {
        userName = profile['username'] ?? 'Your Name';
        userEmail = profile['email'] ?? 'No Email';
        avatarUrl = fetchedAvatarUrl;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching profile: $error')),
      );
    }
  }

  Future<void> _fetchFollowingCount() async {
    final token = await getToken();
    if (token == null) {
      return;
    }

    try {
      final userProfile = await apiService.getUserProfile(token);
      final userId = userProfile['user_id'];

      // Fetch the following list using the user ID
      final followingList = await apiService.getFollowing(token, userId);
      setState(() {
        _followingCount = followingList.length; // Update the following count
      });
    } catch (error) {
      print('Failed to fetch following count: $error');
    }
  }

  Future<void> _fetchFollowerCount() async {
    final token = await getToken();
    if (token == null) {
      return;
    }

    try {
      final userProfile = await apiService.getUserProfile(token);
      final userId = userProfile['user_id'];

      // Fetch followers list using the user ID
      final followersList = await apiService.getFollowers(token, userId);
      setState(() {
        _followerCount = followersList.length; // Update the follower count
      });
    } catch (error) {
      print('Failed to fetch followers count: $error');
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
        userPosts = posts.where((post) => post['post_type'] == 'Furniture' || post['post_type'] == 'Clothes' || post['post_type'] == 'Kitchenware' || post['post_type'] == 'Electronics' || post['post_type'] == 'Miscellaneous' || post['post_type'] == 'Sports').toList();;
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

    if (pickedFile != null) {
      final selectedImage = File(pickedFile.path);

      // Update the profile photo
      await _updateUserPhoto(selectedImage);
    } else {
      print('No image selected');
    }
  }

  Future<void> _updateUserPhoto(File imageFile) async {
    final token = await getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is missing, please log in again')),
      );
      return;
    }

    try {
      final response = await apiService.updateUserProfile(token, avatar: imageFile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Profile photo updated successfully')),
      );

      await _fetchUserProfile();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile photo: $error')),
      );
    }
  }

  Future<void> _deletePost(int postId, int index) async {
    final token = await getToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is missing, please log in again')),
      );
      return;
    }

    try {
      await apiService.deletePost(token, postId);
      setState(() {
        userPosts.removeAt(index); // Remove the deleted post from the list
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete post: $error')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(userEmail ?? 'Loading...', style: const TextStyle(color: Colors.grey)),
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
                    : (avatarUrl != null
                      ? NetworkImage(avatarUrl!) as ImageProvider
                      : AssetImage('assets/images/profile.jpeg')),
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
            Text(userName ?? 'Loading...', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text('$_followerCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('Followers'),
                  ],
                ),
                const SizedBox(width: 50),
                Column(
                  children: [
                    Text('$_followingCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          '${likedPosts.length}',
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
                onRefresh: _fetchAllData,
                child: _showListings && userPosts.isEmpty || !_showListings && likedPosts.isEmpty
                    ? ListView(
                    children: const [
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            "Nothing here, go find something you like!",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                )
                    : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _showListings ? userPosts.length : likedPosts.length,
                    itemBuilder: (context, index) {
                      final data = _showListings ? userPosts[index] : likedPosts[index];
                      final postID = _showListings ? userPosts[index]['post_id'] : likedPosts[index]['post_id'];
                      final imageUrls = _showListings ? postImages[postID] ?? [] : likedPostImages[postID] ?? [];
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '\$${data["price"]?.toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deletePost(postID, index),
                              ),
                            ],
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
