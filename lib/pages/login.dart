import 'package:flutter/material.dart';
import '../auth.dart' as auth;

class LoginPage extends StatelessWidget {
  
	const LoginPage({ super.key });
	
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text("Sign in with Google"),
          onPressed: () async => await auth.signIn(),
        ),
      ),
    );
  }
}
