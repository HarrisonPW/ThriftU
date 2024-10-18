import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://34.69.245.90'; // Replace with your actual backend URL

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data; // Make sure this includes the token
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
        'Authorization': 'Bearer $token', // Include the token in the headers
      },
      body: jsonEncode({
        'post_type': postType,
        'price': price,
        'text': text,
        // If you have file_ids, you can include them here as well
        'file_ids': [], // Update this with actual file IDs if needed
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create post: ${response.statusCode} ${response.body}');
    }
  }




// Add more methods for other endpoints (e.g., activate_user)
}
