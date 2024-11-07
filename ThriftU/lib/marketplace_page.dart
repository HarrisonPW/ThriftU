import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({Key? key}) : super(key: key);

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  int _currentIndex = 0;
  List<dynamic> _furniturePosts = [];
  List<dynamic> _clothesPosts = [];
  List<dynamic> _kitchenwarePosts = [];
  final ApiService apiService = ApiService();
  Map<int, List<String>> postImages = {};

  @override
  void initState() {
    super.initState();
    _fetchPosts(); // Fetch posts when the page loads
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Access route arguments after the context is ready
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['currentIndex'] != null) {
      setState(() {
        _currentIndex = args['currentIndex'];  // Restore the current index for the bottom nav
      });
    }
  }


  Future<String?> getToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      //
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
      final posts = await apiService.getUserPosts(token);

      setState(() {
        // Categorize posts based on post_type
        _furniturePosts = posts.where((post) => post['post_type'] == 'Furniture').toList();
        _clothesPosts = posts.where((post) => post['post_type'] == 'Clothes').toList();
        _kitchenwarePosts = posts.where((post) => post['post_type'] == 'Kitchenware').toList();
      });

      for (var post in posts) {
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

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index; // Update the current index
    });

    // Navigate to the appropriate page based on the tapped index
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/marketplace');
        break;
      case 1:
        Navigator.pushNamed(context, '/plaza'); // Update with actual route
        break;
      case 2:
        Navigator.pushNamed(context, '/post'); // Update with actual route
        break;
      case 3:
        Navigator.pushNamed(context, '/notifications'); // Update with actual route
        break;
      case 4:
        Navigator.pushNamed(context, '/profile'); // Update with actual route
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Marketplace',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFFFFF), // Set AppBar color
        actions: [
          IconButton(
            icon: const Icon(Icons.message, color: Color(0xFF8EACCD)), // Message icon color
            onPressed: () {
              Navigator.pushNamed(context, '/messages'); // Messaging Page
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildMarketplaceBody(),
      ),
    );
  }

  Widget _buildMarketplaceBody() {
    return ListView(
      children: [
        // Search bar
        Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: const TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        // Category: Furniture
        _buildCategorySection(
          title: 'Furnitures',
          posts: _furniturePosts,
        ),
        const SizedBox(height: 16.0),
        // Category: Clothes
        _buildCategorySection(
          title: 'Clothes',
          posts: _clothesPosts,
        ),
        const SizedBox(height: 16.0),
        // Category: Kitchenware
        _buildCategorySection(
          title: 'Kitchenware',
          posts: _kitchenwarePosts,
        ),
      ],
    );
  }

  Widget _buildCategorySection({
    required String title,
    required List<dynamic> posts,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View more',
                style: TextStyle(color: Color(0xFF8EACCD)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        SizedBox(
          height: 180.0,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final postId = post['post_id'];
              final imageUrls = postImages[postId] ?? []; // Get image URLs from postImages map

              return _buildItem(
                name: post['text'], // Title from the post
                imageUrls: imageUrls.isNotEmpty ? imageUrls : ['https://via.placeholder.com/140'], // Use imageUrls or placeholder
                price: post['price'], // Price from the post
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItem({
    required String name,
    required List<String> imageUrls,
    required double price,
  }) {
    return Container(
      width: 140.0, // Width of each item
      margin: const EdgeInsets.only(right: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: imageUrls.length == 1
                ? Image.network(
                  imageUrls[0],
                  height: 120.0,
                  width: 140.0,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.error, size: 50));
                  },
                )
                : SizedBox(
                  height: 120.0,
                  width: 140.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover,
                          width: 140.0,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.error, size: 50));
                          },
                        ),
                      );
                    },
                  ),
                ),
          ),
          const SizedBox(height: 8.0),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

}
