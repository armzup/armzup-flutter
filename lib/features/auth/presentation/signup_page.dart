// lib/features/auth/presentation/signup_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _gymNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _gymAddressController = TextEditingController();
  final _gymPhoneController = TextEditingController();

  File? _logoFile;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _picker = ImagePicker();

  // Take live photo
  Future<void> _takeLivePhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() => _logoFile = File(pickedFile.path));
    }
  }

  // ✅ Cleaned-up signup method
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_logoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please take a live photo 📸")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Signup Successful 🎉 Please login to continue"),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage(role: 'owner')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    _gymNameController.dispose();
    _ownerNameController.dispose();
    _gymAddressController.dispose();
    _gymPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gym Signup")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _takeLivePhoto,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage:
                    _logoFile != null ? FileImage(_logoFile!) : null,
                    child: _logoFile == null
                        ? const Icon(Icons.camera_alt, size: 50)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                const Text("Tap above to take a live photo",
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                _buildTextField(_ownerNameController, "Owner Name", true),
                _buildTextField(_gymNameController, "Gym Name", true),
                _buildTextField(_gymAddressController, "Gym Address", true),
                _buildTextField(_gymPhoneController, "Gym Phone Number", true,
                    type: TextInputType.phone),
                _buildTextField(_emailPhoneController, "Email or Phone", true,
                    type: TextInputType.emailAddress),
                _buildTextField(
                  _passwordController,
                  "Password",
                  true,
                  obscure: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signup,
                  child: const Text("Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, bool requiredField,
      {TextInputType type = TextInputType.text,
        bool obscure = false,
        Widget? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label, suffixIcon: suffixIcon),
        validator: requiredField
            ? (v) {
          if (v == null || v.isEmpty) return "Enter $label";
          if (label.contains("Email") && !v.contains("@") && v.length < 10) {
            return "Enter valid email or phone";
          }
          if (label == "Password" && v.length < 6) {
            return "Password too short";
          }
          return null;
        }
            : null,
      ),
    );
  }
}
