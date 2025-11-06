import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'email_signup_page.dart';
import 'profile_page.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignup() async {
    setState(() => _isLoading = true);
    try {
      final userCred = await _authService.signInWithGoogle();
      if (userCred != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Google Sign-Up failed: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goToEmailSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmailSignupPage()),
    );
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.account_circle),
                    label: const Text("Sign Up with Google"),
                    onPressed: _handleGoogleSignup,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.email),
                    label: const Text("Sign Up with Email"),
                    onPressed: _goToEmailSignup,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _goToLogin,
                    child: const Text("Already a user? Login"),
                  ),
                ],
              ),
      ),
    );
  }
}
