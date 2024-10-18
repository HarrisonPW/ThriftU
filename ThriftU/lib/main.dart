import 'package:flutter/material.dart';
import 'package:thriftu/events.dart';
import 'package:thriftu/main_navigation.dart';
import 'package:thriftu/post.dart';
import 'package:thriftu/restaurants.dart';
import 'package:thriftu/sublease.dart';
import 'package:thriftu/activation_page.dart';
import 'package:thriftu/messages_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'marketplace_page.dart';
import 'plaza_page.dart';
import 'activation_page.dart';
import 'profile_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
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
        '/messages': (context) => const MessagesPage(),
        '/activation': (context) => const ActivationPage(),
        '/profile': (context) => const ProfilePage(),
        '/main_navigation': (context) => const MainNavigation(),
      },
    );
  }
}

