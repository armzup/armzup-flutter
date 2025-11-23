// lib/features/subscriptions/presentation/subscription_popup.dart
import 'package:flutter/material.dart';

class SubscriptionPopup {
  /// Simple dialog used while migrating dashboard. Replace with real UI later.
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Subscription"),
        content: const Text("Your trial/subscription has expired (stub)."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
