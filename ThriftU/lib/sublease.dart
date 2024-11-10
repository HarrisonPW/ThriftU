import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class SubleasePage extends StatefulWidget {
  const SubleasePage({Key? key}) : super(key: key);

  @override
  State<SubleasePage> createState() => _SubleasePageState();
}

class _SubleasePageState extends State<SubleasePage> {
  final TextEditingController _postController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  File? _selectedImage;
  List<dynamic> _posts = [];
  Map<int, List<String>> postImages = {};
  Map<int, List<Map<String, dynamic>>> postReplies = {};
  String? _token;
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeToken();
  }

  Future<void> _initializeToken() async {
    _token = await getToken();
    if (_token != null) {
      _fetchPosts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is missing, please log in again')),
      );
    }
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

  Future<void> _fetchPosts() async {
    try {
      final posts = await _apiService.getAllPosts(_token!);
      setState(() {
        _posts = posts.where((post) => post['post_type'] == 'sublease').toList();
      });

      for (var post in _posts) {
        final postId = post['post_id'];
        _likeCount = await _apiService.getPostLikes(_token!, postId);

        if (post.containsKey('files') && post['files'] != null && post['files'].isNotEmpty) {
          List<String> imageUrls = [];
          for (var fileId in post['files']) {
            final imageUrl = await _apiService.getFileUrl(fileId, _token!);
            imageUrls.add(imageUrl);
          }
          postImages[postId] = imageUrls;
        } else {
          postImages[postId] = [];
        }

        // Fetch replies for each post (add similar checks here if needed)
        final replies = await _apiService.getPostReplies(_token!, postId);
        postReplies[postId] = replies;
      }

      setState(() {}); // Trigger UI update

    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching posts: $error')),
      );
    }
  }

  Future<void> _createPost(String content) async {
    try {
      List<int> fileIds = [];
      final description = _postController.text;
      if (_selectedImage != null) {
        int fileId = await _apiService.uploadFile(_selectedImage!, _token!);
        fileIds.add(fileId);
      }

      await _apiService.createPost(_token!, "sublease", 0, content, description, fileIds);

      _postController.clear();
      setState(() {
        _selectedImage = null;
      });

      _fetchPosts(); // Refresh posts after creating a new one
    } catch (e) {
      print('Error creating post: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _toggleLike(int postId) async {
    try {
      await _apiService.likePost(_token!, postId);
      _fetchPosts(); // Refresh posts to show updated like count
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
    } catch (e) {
      print('Error liking post: $e');
    }
  }

  Future<void> _replyToPost(int postId, String replyText, {int? replyId}) async {
    try {
      await _apiService.replyToPost(_token!, postId, replyText, replyId: replyId);
      _fetchPosts(); // Refresh posts to show updated replies
    } catch (e) {
      print('Error replying to post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sublease Community'),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _posts.isEmpty
                ? const Center(child: Text("No posts available.")) // Display message if no posts
                : ListView.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    final postId = post['post_id'];
                    final imageUrls = postImages[postId] ?? []; // Get image URLs from postImages map
                    final replies = postReplies[postId] ?? []; // Get replies for this post

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post['title'],
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            if (imageUrls.isNotEmpty)
                              SizedBox(
                                height: 150,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: imageUrls.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Image.network(
                                        imageUrls[index],
                                        width: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Posted by: ${post['user_email'] ?? 'Unknown'}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _isLiked ? Icons.favorite : Icons.favorite_border,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _toggleLike(postId),
                                    ),
                                    Text('$_likeCount likes'),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.reply),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        final TextEditingController _replyController = TextEditingController();
                                        return AlertDialog(
                                          title: const Text("Reply to Post"),
                                          content: TextField(
                                            controller: _replyController,
                                            decoration: const InputDecoration(hintText: "Enter your reply here"),
                                          ),
                                          actions: [
                                            TextButton(
                                              child: const Text("Cancel"),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            TextButton(
                                              child: const Text("Reply"),
                                              onPressed: () {
                                                if (_replyController.text.isNotEmpty) {
                                                  _replyToPost(postId, _replyController.text);
                                                  Navigator.of(context).pop();
                                                }
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                            const Divider(),
                            const Text("Replies:"),
                            ...replies.map((reply) {
                              return ListTile(
                                title: Text(reply['reply_text']),
                                subtitle: Text('By: ${reply['user_email'] ?? 'Unknown'}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.reply),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        final TextEditingController _replyController = TextEditingController();
                                        return AlertDialog(
                                          title: const Text("Reply to Comment"),
                                          content: TextField(
                                            controller: _replyController,
                                            decoration: const InputDecoration(hintText: "Enter your reply here"),
                                          ),
                                          actions: [
                                            TextButton(
                                              child: const Text("Cancel"),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            TextButton(
                                              child: const Text("Reply"),
                                              onPressed: () {
                                                if (_replyController.text.isNotEmpty) {
                                                  _replyToPost(postId, _replyController.text, replyId: reply['reply_id']);
                                                  Navigator.of(context).pop();
                                                }
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                },
            ),
          ),
          const Divider(),
          // Post creation section at the bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _postController,
                  decoration: const InputDecoration(
                    hintText: "What's on your mind?",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo),
                      onPressed: _pickImage,
                    ),
                    if (_selectedImage != null)
                      Image.file(
                        _selectedImage!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        if (_postController.text.isNotEmpty) {
                          _createPost(_postController.text);
                        }
                      },
                      child: const Text("Post"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }
}