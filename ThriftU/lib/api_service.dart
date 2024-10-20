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

  Future<void> createPost(String token, String postType, double price, String text) async {
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
        'file_ids': [],
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create post: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> uploadFile(File file, String token) async {
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

    if (response.statusCode == 200) {
      print("File uploaded successfully.");
    } else {
      throw Exception('Failed to upload file: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getUserPosts(String token) async {
    final url = Uri.parse('$baseUrl/posts');
    final response = await http.get(
      url,
      headers: {
        'Authorization': token,
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



// Add more methods for other endpoints (e.g., activate_user)
}
