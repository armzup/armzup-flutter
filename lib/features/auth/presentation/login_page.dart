import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  final String role;
  const LoginPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$role Login')),
      body: Center(
        child: Text('Login Page for $role', style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
