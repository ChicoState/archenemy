import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'login.dart';

class SettingsScreen extends StatelessWidget {
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: Icon(Icons.logout),
        label: Text("Logout"),
        onPressed: () async {
          await authService.signOut();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => LoginPage()),
          );
        },
      ),
    );
  }
}
