// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/post_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/posts_screen.dart'; 

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PostProvider()),
      ],
      child: MaterialApp(
        title: 'Centro Cultural UNSA',
        theme: ThemeData(primarySwatch: Colors.red),
        home: WelcomeScreen(),
        routes: {
          '/posts': (context) => PostsScreen(),
        },
      ),
    );
  }
}