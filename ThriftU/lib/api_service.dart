import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class ApiService {
  static const String baseUrl = 'http://34.44.172.61';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to log in: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String username) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'username': username,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body); // Handle successful registration
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }


  Future<Map<String, dynamic>> activateUser(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/activate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Handle successful activation
    } else {
      throw Exception('Failed to activate user: ${response.body}');
    }
  }

  Future<void> createPost(String token, String postType, double price, String title, String description, List<int> fileIds) async {
    final response = await http.post(
      Uri.parse('$baseUrl/post'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': '$token',
      },
      body: jsonEncode({
        'post_type': postType,
        'price': price,
        'title': title,
        'description': description,
        'file_ids': fileIds,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create post: ${response.statusCode} ${response.body}');
    }
  }

  Future<int> uploadFile(File file, String token) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

    // Attach the file
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: basename(file.path),
      ),
    );

    request.headers['Authorization'] = '$token';
    request.headers['Content-Type'] = 'multipart/form-data';

    var response = await request.send();

    if (response.statusCode == 201) {
      print("File uploaded successfully.");
      final responseData = await http.Response.fromStream(response);
      final data = jsonDecode(responseData.body);
      return data['file_id'];
    } else {
      throw Exception('Failed to upload file: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getUserPosts(String token) async {
    final url = Uri.parse('$baseUrl/posts');
    final response = await http.get(
      url,
      headers: {
        'Authorization': '$token',
      },
    );

    print(response.body);

    if (response.statusCode == 200) {
      print("Data fetched successfully.");
      final responseData = jsonDecode(response.body);
      return responseData['posts'];
    } else {
      throw Exception('Failed to load posts: ${response.statusCode}');
    }
  }

  Future<String> getFileUrl(int fileId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/file/$fileId'),
      headers: {
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      return response.request!.url.toString(); // Returns the URL of the image
    } else {
      throw Exception('Failed to load file: ${response.statusCode}');
    }
  }


  static Future<List<Map<String, dynamic>>> fetchMessages(String token) async {
    final url = Uri.parse('$baseUrl/chat2/messages');
    print("Fetching messages from: $url with token: $token"); // Debug: URL and token

    final response = await http.get(
      url,
      headers: {'Authorization': token},
    );

    print("Response status code: ${response.statusCode}"); // Debug: Status code
    print("Response body: ${response.body}"); // Debug: Raw response body

    if (response.statusCode == 200) {
      try {
        final responseData = jsonDecode(response.body);
        print("Decoded response: $responseData");
        if (responseData['messages'] == null) {
          throw Exception("Missing 'messages' key in response");
        }

        return List<Map<String, dynamic>>.from(responseData['messages']);
      } catch (e) {
        print("JSON decoding error: $e");
        throw Exception('Invalid JSON response: $e');
      }
    } else {
      print("Failed to fetch messages: ${response.statusCode}"); // Debug: Error response
      throw Exception('Failed to fetch messages: ${response.statusCode}');
    }
  }


  static Future<void> sendMessage(String token, int toUserId, String text) async {
    final url = Uri.parse('$baseUrl/chat2/send');
    final response = await http.post(
      url,
      headers: {'Authorization': token, 'Content-Type': 'application/json'},
      body: jsonEncode({'to_user_id': toUserId, 'text': text}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>?> searchUser(String token, String email) async {
    final url = Uri.parse('$baseUrl/search_user?email=$email');
    final response = await http.get(url, headers: {'Authorization': token});

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null; // User not found
    } else {
      throw Exception('Failed to search user: ${response.body}');
    }
  }

  Future<void> likePost(String token, int postId) async {
    final url = Uri.parse('$baseUrl/like');
    final response = await http.post(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'post_id': postId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to like/unlike post: ${response.body}');
    }
  }

  Future<int> getPostLikes(String token, int postId) async {
    final url = Uri.parse('$baseUrl/post/$postId/likes');
    final response = await http.get(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['like_count'];
    } else {
      throw Exception('Failed to retrieve like count: ${response.body}');
    }
  }

  Future<void> replyToPost(String token, int postId, String replyText, {int? replyId}) async {
    final url = Uri.parse('$baseUrl/reply');
    final response = await http.post(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'to_post_id': postId,
        'reply_text': replyText,
        'to_reply_id': replyId, // Optional if replying to another comment
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to post reply: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getPostReplies(String token, int postId) async {
    final url = Uri.parse('$baseUrl/post/$postId/replies');
    final response = await http.get(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['replies']);
    } else {
      throw Exception('Failed to retrieve replies: ${response.body}');
    }
  }

  Future<void> deletePost(String token, int postId) async {
    final url = Uri.parse('$baseUrl/post/delete');
    final response = await http.post(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'post_id': postId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete post: ${response.body}');
    }
  }

  Future<void> deleteReply(String token, int replyId) async {
    final url = Uri.parse('$baseUrl/reply/delete');
    final response = await http.post(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reply_id': replyId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete reply: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getPostDetails(String token, int postId) async {
    final url = Uri.parse('$baseUrl/post/$postId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['post']; // Extract 'post' from the response
    } else {
      throw Exception('Failed to fetch post details: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getAllPosts(String token) async {
    final url = Uri.parse('$baseUrl/all_posts');
    final response = await http.get(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['posts']);
    } else {
      throw Exception('Failed to fetch posts: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String token) async {
    final url = Uri.parse('$baseUrl/user/profile');
    final response = await http.get(
      url,
      headers: {
        'Authorization': '$token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } else if (response.statusCode == 404) {
      throw Exception('User not found: ${response.body}');
    } else {
      throw Exception('Failed to fetch user profile: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(String token, {File? avatar}) async {
    final url = Uri.parse('$baseUrl/user/profile');
    final request = http.MultipartRequest('PUT', url);

    request.headers['Authorization'] = '$token';

    if (avatar != null) {
      final fileName = avatar.path.split('/').last;
      request.files.add(
        await http.MultipartFile.fromPath('avatar', avatar.path, filename: fileName),
      );
    }

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } else if (response.statusCode == 400) {
      throw Exception('Bad request: ${response.body}');
    } else {
      throw Exception('Failed to update user profile: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getUserLikedPosts(String token) async {
    final url = Uri.parse('$baseUrl/user/liked_posts');
    final response = await http.get(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['liked_posts']);
    } else if (response.statusCode == 404) {
      return []; // Return empty list if no liked posts are found
    } else {
      throw Exception('Failed to fetch liked posts: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotifications(String token, List<int> userPostIds) async {
    final List<Map<String, dynamic>> notifications = [];

    try {
      // Fetch messages
      final messages = await ApiService.fetchMessages(token);
      for (var message in messages) {
        notifications.add({
          'id': message['message_id'],
          'type': 'Message',
          'content': 'New message from ${message['sender']}',
          'timestamp': message['timestamp'],
          'is_read': message['is_read'] ?? false,
        });
      }

      // Fetch replies for each post owned by the user
      for (var postId in userPostIds) {
        final replies = await getPostReplies(token, postId);
        for (var reply in replies) {
          notifications.add({
            'id': reply['reply_id'],
            'type': 'Reply',
            'content': 'New reply to your post: "${reply['content']}"',
            'timestamp': reply['timestamp'],
            'is_read': reply['is_read'] ?? false,
          });
        }
      }

      return notifications;
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  Future<Map<String, dynamic>> getUserProfileById(String token, int userId) async {
    final url = Uri.parse('$baseUrl/user/profile/$userId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } else if (response.statusCode == 404) {
      throw Exception('User not found: ${response.body}');
    } else {
      throw Exception('Failed to fetch user profile: ${response.body}');
    }
  }

  Future<void> followUser(String token, int userId) async {
    final url = Uri.parse('$baseUrl/follow');
    final response = await http.post(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'following_id': userId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to follow user: ${response.body}');
    }
  }

  Future<void> unfollowUser(String token, int userId) async {
    final url = Uri.parse('$baseUrl/unfollow');
    final response = await http.post(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'following_id': userId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to unfollow user: ${response.body}');
    }
  }

  Future<List<int>> getFollowing(String token, int userId) async {
    final url = Uri.parse('$baseUrl/following/$userId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final followingList = List<Map<String, dynamic>>.from(data['following']);
      return followingList.map((user) => user['user_id'] as int).toList();
    } else {
      throw Exception('Failed to fetch following list: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getFollowers(String token, int userId) async {
    final url = Uri.parse('$baseUrl/followers/$userId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final followersList = List<Map<String, dynamic>>.from(data['followers']);
      return followersList;
    } else {
      throw Exception('Failed to fetch followers: ${response.body}');
    }
  }

// Add more methods for other endpoints (e.g., activate_user)
}
