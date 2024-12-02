import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'plaza_details_page.dart';
import 'plaza_post.dart';

class PlazaPage extends StatefulWidget {
  const PlazaPage({Key? key}) : super(key: key);

  @override
  State<PlazaPage> createState() => _PlazaPageState();
}

class _PlazaPageState extends State<PlazaPage> {
  final ApiService apiService = ApiService();
  List<dynamic> _allPosts = [];
  List<dynamic> _filteredPosts = [];
  Map<int, List<String>> postImages = {};
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _fetchPosts(); // Fetch posts when the page loads
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
    final token = await getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is missing, please log in again')),
      );
      return;
    }

    try {
      final posts = await apiService.getAllPosts(token);

      setState(() {
        _allPosts = posts.where((post) => ['sublease', 'restaurant', 'event'].contains(post['post_type'])).toList();
        _filteredPosts = _allPosts; // Initially show all posts
      });

      for (var post in _allPosts) {
        if (post['files'] != null && post['files'].isNotEmpty) {
          List<String> imageUrls = [];
          for (var fileId in post['files']) {
            final imageUrl = await apiService.getFileUrl(fileId, token);
            imageUrls.add(imageUrl);
          }
          postImages[post['post_id']] = imageUrls; // Store list of image URLs in the map
        } else {
          postImages[post['post_id']] = []; // No images if there are no file_ids
        }
      }

      setState(() {});
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching posts: $error')),
      );
    }
  }

  void _filterPosts(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        _filteredPosts = _allPosts;
      } else {
        _filteredPosts = _allPosts.where((post) => post['post_type'] == category.toLowerCase()).toList();
      }
    });
  }

  Future<void> _navigateToDetails(int postId) async {
    final token = await getToken();
    if (token != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlazaDetailsPage(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Plaza',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFFFFFF),
        actions: [
          PopupMenuButton<String>(
            onSelected: _filterPosts,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(value: 'Sublease', child: Text('Sublease')),
              const PopupMenuItem(value: 'Restaurant', child: Text('Restaurant')),
              const PopupMenuItem(value: 'Event', child: Text('Event')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchPosts,
                child: _buildPlazaBody(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SafeArea(
        child: FloatingActionButton(
          onPressed: () async {
            final token = await getToken();
            if (token != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlazaPostPage(
                    token: token,
                    categories: ['sublease', 'restaurant', 'event'],
                    onPostCreated: _fetchPosts,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Token is missing, please log in again')),
              );
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildPlazaBody() {
    return _filteredPosts.isEmpty
        ? const Center(child: Text('No posts available.'))
        : ListView.builder(
      itemCount: _filteredPosts.length,
      itemBuilder: (context, index) {
        final post = _filteredPosts[index];
        final postId = post['post_id'];
        final imageUrls = postImages[postId] ?? [];

        return _buildPostItem(
          name: post['title'] ?? 'Untitled',
          description: post['description'] ?? '',
          imageUrls: imageUrls.isNotEmpty ? imageUrls : ['https://via.placeholder.com/140'],
          postId: postId,
        );
      },
    );
  }

  Widget _buildPostItem({
    required String name,
    required String description,
    required List<String> imageUrls,
    required int postId,
  }) {
    return GestureDetector(
      onTap: () => _navigateToDetails(postId),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: Image.network(
                  imageUrls[0],
                  height: 200.0,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
