import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class ApiService {
  final String baseUrl = 'http://34.69.245.90';

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

  Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
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

  Future<void> createPost(String token, String postType, double price, String text, List<int> fileIds) async {
    final response = await http.post(
      Uri.parse('$baseUrl/post'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': '$token',
      },
      body: jsonEncode({
        'post_type': postType,
        'price': price,
        'text': text,
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


  Future<void> sendMessage(String token, int toUserId, String postId, String text) async {
    final url = Uri.parse('$baseUrl/chat/send');

    print("Sending message with parameters:");
    print("to_user_id: $toUserId");
    print("post_id: ${postId.isEmpty ? 'null' : postId}");
    print("text: $text");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: jsonEncode({
        'to_user_id': toUserId,
        'post_id': postId,
        'text': text,
      }),
    );

    print(response.statusCode);
    print(response.body);

    if (response.statusCode != 201) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMessages(String token) async {
    final url = Uri.parse('$baseUrl/chat/messages');
    final response = await http.get(
      url,
      headers: {
        'Authorization': token,
      },
    );
    print(response.body);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(responseData['messages']);
    } else {
      throw Exception('Failed to fetch messages: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map<String, dynamic>?> searchUser(String token, String email) async {
    final url = Uri.parse('$baseUrl/search_user?email=$email');
    final response = await http.get(
      url,
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
    );

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

// Add more methods for other endpoints (e.g., activate_user)
}
