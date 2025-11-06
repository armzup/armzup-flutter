import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final String userId;
  const DashboardPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: Text('Welcome to Dashboard!\nUser ID: $userId',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
