import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'item_details_page.dart';
//import 'package:firebase_analytics/firebase_analytics.dart';

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
  List<dynamic> _electronicsPosts = [];
  List<dynamic> _miscellaneousPosts = [];
  List<dynamic> _sportsPosts = [];
  String _searchQuery = '';
  List<dynamic> _allPosts = [];
  final TextEditingController _searchController = TextEditingController();
  // final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  // Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    //_startTimer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // @override
  // void dispose() {
  //   super.dispose();
  //   _stopTimer();
  // }
  //
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
        _allPosts = posts;
        _furniturePosts = posts.where((post) => post['post_type'] == 'Furniture').toList();
        _clothesPosts = posts.where((post) => post['post_type'] == 'Clothes').toList();
        _kitchenwarePosts = posts.where((post) => post['post_type'] == 'Kitchenware').toList();
        _electronicsPosts = posts.where((post) => post['post_type'] == 'Electronics').toList();
        _miscellaneousPosts = posts.where((post) => post['post_type'] == 'Miscellaneous').toList();
        _sportsPosts = posts.where((post) => post['post_type'] == 'Sports').toList();
      });

      for (var post in posts) {
        if (post['files'] != null && post['files'].isNotEmpty) {
          List<String> imageUrls = [];
          for (var fileId in post['files']) {
            final imageUrl = await apiService.getFileUrl(fileId, token);
            print(imageUrl);
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

  List<dynamic> _filterPostsBySearchQuery(List<dynamic> posts) {
    if (_searchQuery.isEmpty) return posts;

    return posts.where((post) {
      final title = post['title']?.toLowerCase() ?? '';
      return title.contains(_searchQuery);
    }).toList();
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
              // _analytics.logEvent(
              //   name: 'button_click',
              //   parameters: {
              //     'button_name': 'message_button',
              //   },
              // );
              Navigator.pushNamed(context, '/messages'); // Messaging Page
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: _fetchPosts,
          child: _buildMarketplaceBody(),
        ),
      ),
    );
  }

  Widget _buildMarketplaceBody() {
    final filteredPosts = _filterPostsBySearchQuery(_allPosts); // Filter all posts

    return Column(
      children: [
        // Search bar
        Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase(); // Update query for case-insensitive search
              });
            },
            decoration: InputDecoration(
              hintText: 'Search',
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                  : null,
            ),
          ),
        ),
        // Show results or default view
        Expanded(
          child: _searchQuery.isNotEmpty
              ? (filteredPosts.isEmpty
              ? const Center(
            child: Text('No items match your search.'),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredPosts.length,
            itemBuilder: (context, index) {
              final post = filteredPosts[index];
              final postId = post['post_id'];
              final imageUrls = postImages[postId] ?? [];

              return _buildItem(
                name: post['title'],
                imageUrls: imageUrls.isNotEmpty
                    ? imageUrls
                    : ['https://via.placeholder.com/140'],
                price: post['price'],
                postId: postId,
              );
            },
          ))
              : ListView(
              children: [
                _buildCategorySection(
                  title: 'Furniture',
                  posts: _furniturePosts,
                ),
                const SizedBox(height: 16.0),
                _buildCategorySection(
                  title: 'Clothes',
                  posts: _clothesPosts,
                ),
                const SizedBox(height: 16.0),
                _buildCategorySection(
                  title: 'Kitchenware',
                  posts: _kitchenwarePosts,
                ),
                const SizedBox(height: 16.0),
                _buildCategorySection(
                  title: 'Electronics',
                  posts: _electronicsPosts,
                ),
                const SizedBox(height: 16.0),
                _buildCategorySection(
                  title: 'Miscellaneous',
                  posts: _miscellaneousPosts,
                ),
                const SizedBox(height: 16.0),
                _buildCategorySection(
                  title: 'Sports',
                  posts: _sportsPosts,
                ),
              ],
          ),
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
                name: post['title'],
                imageUrls: imageUrls.isNotEmpty ? imageUrls : ['https://via.placeholder.com/140'],
                price: post['price'],
                postId: postId,
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
    required int postId,
  }) {
    return GestureDetector(
      onTap: () => _navigateToDetails(postId),
      child: Container(
        width: 140.0,
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
      ),
    );
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
        Navigator.pushNamed(context, '/plaza');
        break;
      case 2:
        Navigator.pushNamed(context, '/post');
        break;
      case 3:
        Navigator.pushNamed(context, '/notifications');
        break;
      case 4:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }
}
