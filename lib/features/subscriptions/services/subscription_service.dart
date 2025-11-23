// lib/features/subscriptions/services/subscription_service.dart
import 'dart:async';

class SubscriptionService {
  final String ownerId;
  SubscriptionService({required this.ownerId});

  /// Returns remaining days (stub: returns 0)
  Future<int> remainingDays() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return 0;
  }

  /// Returns expiry date if any (stub: null)
  Future<DateTime?> getExpiryDate() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return null;
  }

  /// Activate or extend subscription by [days] (stub: no-op)
  Future<void> activateSubscription(int days) async {
    await Future.delayed(const Duration(milliseconds: 50));
    // no-op stub
  }
}
