import 'package:flutter/material.dart';
import 'bottom_navigation_bar.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({Key? key}) : super(key: key);

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  int _currentIndex = 0; // Track the current index for the bottom navigation bar

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
        child: ListView(
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
            // Category Section 1
            _buildCategorySection(
              title: 'Furnitures',
              items: [
                _buildItem('Sofa', 'https://via.placeholder.com/140', 57.0),
                _buildItem('Table chair', 'https://via.placeholder.com/140', 20.0),
                _buildItem('Chair', 'https://via.placeholder.com/140', 15.0),
                _buildItem('Mattress', 'https://via.placeholder.com/140', 50.0),
              ],
            ),
            const SizedBox(height: 16.0),
            // Category Section 2
            _buildCategorySection(
              title: 'Clothes',
              items: [
                _buildItem('Suit', 'https://via.placeholder.com/140', 15.0),
                _buildItem('T-shirt', 'https://via.placeholder.com/140', 10.0),
                _buildItem('Dress', 'https://via.placeholder.com/140', 25.0),
                _buildItem('Tie', 'https://via.placeholder.com/140', 5.0),
              ],
            ),
            const SizedBox(height: 16.0),
            // Category Section 3
            _buildCategorySection(
              title: 'Kitchenware',
              items: [
                _buildItem('Spatula', 'https://via.placeholder.com/140', 2.0),
                _buildItem('Bowls', 'https://via.placeholder.com/140', 5.0),
                _buildItem('Cutleries', 'https://via.placeholder.com/140', 15.0),
                _buildItem('Blender', 'https://via.placeholder.com/140', 20.0),
              ],
            ),
            const SizedBox(height: 16.0),
            // Add more categories similarly if needed...
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  // Widget to build a category section with horizontal scroll
  Widget _buildCategorySection({
    required String title,
    required List<Widget> items,
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
          height: 180.0, // Height for each horizontal scroll section
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: items,
          ),
        ),
      ],
    );
  }

  // Widget to build a single item in a horizontal list
  Widget _buildItem(String name, String imageUrl, double price) {
    return Container(
      width: 140.0, // Width of each item
      margin: const EdgeInsets.only(right: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Image.network(
              imageUrl,
              height: 120.0,
              width: 140.0,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.error, size: 50));
              },
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
