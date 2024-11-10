import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

class ItemDetailsPage extends StatefulWidget {
  final int postId;
  final String token;

  const ItemDetailsPage({Key? key, required this.postId, required this.token}) : super(key: key);

  @override
  _ItemDetailsPageState createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _postDetails;
  List<Map<String, dynamic>> _replies = [];
  bool _isLiked = false;
  int _likeCount = 0;
  final TextEditingController _commentController = TextEditingController(); // Controller for comment input

  @override
  void initState() {
    super.initState();
    _fetchPostDetails();
    _fetchReplies();
    _fetchLikeCount();
  }

  Future<void> _fetchPostDetails() async {
    try {
      final details = await _apiService.getPostDetails(widget.token, widget.postId);
      List<String> imageUrls = [];
      for (var fileId in details['files']) {
        final imageUrl = await _apiService.getFileUrl(fileId, widget.token);
        print(imageUrl);
        imageUrls.add(imageUrl);
      }
      setState(() {
        _postDetails = details;
        _postDetails!['files'] = imageUrls;
      });
    } catch (e) {
      print('Failed to fetch post details: $e');
    }
  }

  Future<void> _fetchReplies() async {
    try {
      final replies = await _apiService.getPostReplies(widget.token, widget.postId);
      setState(() {
        _replies = replies;
      });
    } catch (e) {
      print('Failed to fetch replies: $e');
    }
  }

  Future<void> _fetchLikeCount() async {
    try {
      final likeCount = await _apiService.getPostLikes(widget.token, widget.postId);
      setState(() {
        _likeCount = likeCount;
      });
    } catch (e) {
      print('Failed to fetch like count: $e');
    }
  }

  Future<void> _toggleLike() async {
    try {
      await _apiService.likePost(widget.token, widget.postId);
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
    } catch (e) {
      print('Failed to toggle like: $e');
    }
  }

  Future<void> _postReply(String replyText) async {
    try {
      await _apiService.replyToPost(widget.token, widget.postId, replyText);
      _commentController.clear(); // Clear the text field after posting
      _fetchReplies(); // Refresh replies after posting
    } catch (e) {
      print('Failed to post reply: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
      ),
      body: _postDetails == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display item details
                Text(
                  _postDetails!['title'],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('Posted by: ${_postDetails!['user_email']}'),
                const SizedBox(height: 10),
                Text('Price: \$${_postDetails!['price'].toStringAsFixed(2)}'),
                const SizedBox(height: 10),

                // Display post images
                if (_postDetails!['files'] != null)
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _postDetails!['files'].length,
                      itemBuilder: (context, index) {
                        final imageUrl = _postDetails!['files'][index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Image.network(imageUrl, fit: BoxFit.cover),
                        );
                      },
                    ),
                  ),

              const SizedBox(height: 20),
              Text('Description: ${_postDetails!['description']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Like and comment section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: _toggleLike,
                  ),
                  Text('$_likeCount likes'),
                ],
              ),
              const Divider(),

              // Comments section
              const Text(
                'Comments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _replies.length,
                  itemBuilder: (context, index) {
                    final reply = _replies[index];
                    return ListTile(
                      title: Text(reply['reply_text']),
                      subtitle: Text('by ${reply['email']} on ${reply['create_time']}'),
                    );
                  },
                ),
              ),
              const Divider(),

              // Reply input field
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                        ),
                        onSubmitted: (text) {
                          if (text.isNotEmpty) {
                            _postReply(text);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        if (_commentController.text.isNotEmpty) {
                          _postReply(_commentController.text);
                        }
                      },
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
