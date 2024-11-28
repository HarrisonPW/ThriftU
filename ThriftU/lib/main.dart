import 'package:flutter/material.dart';
import 'package:thriftu/events.dart';
import 'package:thriftu/main_navigation.dart';
import 'package:thriftu/post.dart';
import 'package:thriftu/restaurants.dart';
import 'package:thriftu/sublease.dart';
import 'package:thriftu/activation_page.dart';
import 'package:thriftu/messages_page.dart';
import 'auth_provider.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'marketplace_page.dart';
import 'plaza_page.dart';
import 'activation_page.dart';
import 'profile_page.dart';

import 'package:provider/provider.dart';
import 'chat_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/marketplace': (context) => const MarketplacePage(),
        '/plaza': (context) => const PlazaPage(),
        '/sublease': (context) => const SubleasePage(),
        '/restaurants': (context) => const RestaurantsPage(),
        '/events': (context) => const EventsPage(),
        '/post': (context) => const PostPage(),
        '/messages': (context) => MessagesPage(),
        '/activation': (context) => const ActivationPage(),
        '/profile': (context) => const ProfilePage(),
        '/main_navigation': (context) => const MainNavigation(),
      },
    );
  }
}


