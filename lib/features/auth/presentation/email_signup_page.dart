import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'profile_page.dart';

class EmailSignupPage extends StatefulWidget {
  const EmailSignupPage({super.key});

  @override
  State<EmailSignupPage> createState() => _EmailSignupPageState();
}

class _EmailSignupPageState extends State<EmailSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _auth.signUpWithEmail(_email.text, _password.text);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Signup failed: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up with Email")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: "Email"),
                      validator: (v) =>
                          v!.isEmpty ? "Enter email" : null,
                    ),
                    TextFormField(
                      controller: _password,
                      decoration: const InputDecoration(labelText: "Password"),
                      obscureText: true,
                      validator: (v) =>
                          v!.length < 6 ? "Min 6 characters" : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _signup,
                      child: const Text("Continue"),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
