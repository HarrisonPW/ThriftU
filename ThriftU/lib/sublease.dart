import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SubleasePage extends StatefulWidget {
  const SubleasePage({super.key});

  @override
  State<SubleasePage> createState() => _SubleasePageState();
}

class _SubleasePageState extends State<SubleasePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sublease Community'),
        backgroundColor: const Color(0xFFFFFF), // Set AppBar color
      ),
      body: Center(
        child: const Text(
          'Welcome to the sublease posts!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}