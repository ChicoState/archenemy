import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'main.dart';

class LoginPage extends StatelessWidget {
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text("Sign in with Google"),
          onPressed: () async {
            final user = await authService.signInWithGoogle();
            if (user != null && context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const App()),
              );
            }
          },
        ),
      ),
    );
  }
}
