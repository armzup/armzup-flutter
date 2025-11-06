import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../dashboard/presentation/dashboard_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _ownerName = TextEditingController();
  final _gymName = TextEditingController();
  final _address = TextEditingController();
  bool _isLoading = false;

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'ownerName': _ownerName.text.trim(),
        'gymName': _gymName.text.trim(),
        'address': _address.text.trim(),
        'email': FirebaseAuth.instance.currentUser!.email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DashboardPage(userId: FirebaseAuth.instance.currentUser!.uid),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving profile: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _ownerName,
                      decoration: const InputDecoration(labelText: "Owner Name"),
                      validator: (v) => v!.isEmpty ? "Enter name" : null,
                    ),
                    TextFormField(
                      controller: _gymName,
                      decoration: const InputDecoration(labelText: "Gym Name"),
                      validator: (v) => v!.isEmpty ? "Enter gym name" : null,
                    ),
                    TextFormField(
                      controller: _address,
                      decoration:
                          const InputDecoration(labelText: "Gym Address"),
                      validator: (v) => v!.isEmpty ? "Enter address" : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _createAccount,
                      child: const Text("Create Account"),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
