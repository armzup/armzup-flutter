// lib/features/members/presentation/add_member_page.dart
import 'package:flutter/material.dart';

class AddMemberPage extends StatelessWidget {
  const AddMemberPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Member (stub)")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.person_add, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text("Add Member Page (stub)"),
            SizedBox(height: 8),
            Text("Replace with your real AddMemberPage when ready."),
          ],
        ),
      ),
    );
  }
}
