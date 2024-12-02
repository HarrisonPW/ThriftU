import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> loginUser() async {
    if (!_validateInput()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (response != null) {
        if (response['error'] == 'User not activated') {
          _showMessage('Please activate your account first.');
          Navigator.pushNamed(context, '/activation');
        } else {
          final String token = response['token'];
          await _saveToken(token);
          Navigator.pushReplacementNamed(context, '/main_navigation');
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validateInput() {
    if (_emailController.text.trim().isEmpty) {
      _showMessage('Please enter your email');
      return false;
    }
    if (_passwordController.text.isEmpty) {
      _showMessage('Please enter your password');
      return false;
    }
    return true;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom - 32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'thriftU',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8EACCD),
                  ),
                ),
                const SizedBox(height: 50),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => loginUser(),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : loginUser,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Login'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text('Don\'t have an account? Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
