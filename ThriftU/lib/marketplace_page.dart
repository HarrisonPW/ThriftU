import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({Key? key}) : super(key: key);

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  int _currentIndex = 0; // Track the current index for the bottom navigation bar
  List<dynamic> _posts = []; // To hold the fetched posts

  @override
  void initState() {
    super.initState();
    _fetchPosts(); // Fetch posts when the page loads
  }

  Future<void> _fetchPosts() async {
    try {
      final response = await http.get(Uri.parse('http://34.69.245.90/posts')); // Update with your API endpoint

      if (response.statusCode == 200) {
        setState(() {
          _posts = jsonDecode(response.body); // Update the state with fetched posts
        });
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (error) {
      // Handle error (show snackbar or dialog)
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
        child: _posts.isEmpty
            ? const Center(child: CircularProgressIndicator()) // Loading indicator
            : ListView.builder(
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            final post = _posts[index];
            return _buildItem(
              post['text'], // Title from the post
              post['image_url'], // Image URL (add this field to your post model)
              post['price'], // Price from the post
            );
          },
        ),
      ),
    );
  }

  // Widget to build a single item in the marketplace
  Widget _buildItem(String name, String imageUrl, double price) {
    return GestureDetector(
      onTap: () {
        // Navigate to the post details page, passing the post data
        Navigator.pushNamed(context, '/postDetails', arguments: {
          'name': name,
          'imageUrl': imageUrl,
          'price': price,
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.network(
                imageUrl,
                height: 100.0,
                width: 100.0,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.error, size: 50));
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
          ],
        ),
      ),
    );
  }
}
