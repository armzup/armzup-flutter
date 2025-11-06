import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; 

import 'features/auth/presentation/pre_login_page.dart';
import 'features/dashboard/presentation/dashboard_page.dart';

void main() async {
  // Ensures Flutter is ready before Firebase starts.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Management App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthWrapper(), // 👈 handles the redirection
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          // User is logged in
          return DashboardPage(userId: snapshot.data!.uid);
        } else {
          // User is not logged in
          return const PreLoginPage();
        }
      },
    );
  }
}