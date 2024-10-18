import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key});

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Restaurants'),
        backgroundColor: const Color(0xFFFFFF), // Set AppBar color
      ),
      body: Center(
        child: const Text(
          'food explorations!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}