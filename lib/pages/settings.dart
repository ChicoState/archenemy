import 'package:flutter/material.dart';
import '../auth.dart';
import 'login.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: Icon(Icons.logout),
        label: Text("Logout"),
        onPressed: () async {
          await signOut();
        },
      ),
    );
  }
}
