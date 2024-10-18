import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventaPageState();
}

class _EventaPageState extends State<EventsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events around me'),
        backgroundColor: const Color(0xFFFFFF), // Set AppBar color
      ),
      body: Center(
        child: const Text(
          'Welcome to the posts for events!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}