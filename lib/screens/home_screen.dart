// lib/screens/home_screen.dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Archnemesis Home"),
      ),
      body: Center(
        child: const Text(
          "Welcome to Archnemesis!",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
