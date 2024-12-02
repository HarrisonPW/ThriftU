import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'api_service.dart';

class PlazaPostPage extends StatefulWidget {
  final String token;
  final List<String> categories; // Accept categories for the post
  final VoidCallback onPostCreated;

  const PlazaPostPage({
    Key? key,
    required this.token,
    required this.categories,
    required this.onPostCreated,
  }) : super(key: key);

  @override
  State<PlazaPostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PlazaPostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _selectedCategory;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _createPost() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    try {
      final apiService = ApiService();
      List<int> fileIds = [];

      if (_selectedImage != null) {
        int fileId = await apiService.uploadFile(_selectedImage!, widget.token);
        fileIds.add(fileId);
      }

      await apiService.createPost(
        widget.token,
        _selectedCategory!,
        0,
        _titleController.text,
        _descriptionController.text,
        fileIds,
      );

      widget.onPostCreated(); // Notify PlazaPage to refresh posts
      Navigator.pop(context); // Go back to PlazaPage
    } catch (e) {
      print("Error creating post: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error creating post')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
      FocusScope.of(context).unfocus();
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              onChanged: (value) => setState(() => _selectedCategory = value),
              items: widget.categories
                  .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                  .toList(),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImage,
                ),
                if (_selectedImage != null)
                  Image.file(
                    _selectedImage!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _createPost,
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
