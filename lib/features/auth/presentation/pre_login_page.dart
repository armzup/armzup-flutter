import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';

class PreLoginPage extends StatefulWidget {
  const PreLoginPage({super.key});

  @override
  State<PreLoginPage> createState() => _PreLoginPageState();
}

class _PreLoginPageState extends State<PreLoginPage> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<Map<String, String>> _pages = [
    {
      'title': 'Manage Your Gym Effortlessly',
      'subtitle': 'All-in-one gym management for owners and trainers',
    },
    {
      'title': 'Member Management Made Simple',
      'subtitle': 'Add, renew, and track member progress easily',
    },
    {
      'title': 'Payment Tracking Simplified',
      'subtitle': 'Never miss a renewal or due payment again',
    },
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupPage()),
    );
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage(role: 'owner')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goToLogin,
                child: const Text("Skip"),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fitness_center,
                            size: 100, color: Colors.blue.shade600),
                        const SizedBox(height: 40),
                        Text(
                          page['title']!,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page['subtitle']!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.blue.shade600
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _currentPage < _pages.length - 1
                      ? _nextPage
                      : _goToSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1
                        ? 'Continue'
                        : 'Start Free Trial',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
