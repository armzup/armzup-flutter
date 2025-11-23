// lib/features/dashboard/services/dashboard_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardService {
  final String ownerId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DashboardService({required this.ownerId});

  /// Fetch all members for the gym
  Future<List<Map<String, dynamic>>> fetchMembers() async {
    final snapshot = await _firestore
        .collection('members')
        .where('ownerId', isEqualTo: ownerId)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Fetch recent transactions
  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Get subscription expiry date
  Future<DateTime?> getSubscriptionExpiryDate() async {
    final doc = await _firestore.collection('subscriptions').doc(ownerId).get();
    if (!doc.exists) return null;
    final timestamp = doc['endDate'] as Timestamp?;
    return timestamp?.toDate();
  }

  /// Calculate remaining days for subscription
  Future<int> getRemainingDays() async {
    final expiry = await getSubscriptionExpiryDate();
    if (expiry == null) return 0;
    final days = expiry.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  /// Renew subscription by adding days
  Future<void> renewSubscription({int days = 30}) async {
    final expiry = await getSubscriptionExpiryDate();
    final newExpiry =
    expiry != null && expiry.isAfter(DateTime.now())
        ? expiry.add(Duration(days: days))
        : DateTime.now().add(Duration(days: days));

    await _firestore.collection('subscriptions').doc(ownerId).update({
      'endDate': Timestamp.fromDate(newExpiry),
      'isActive': true,
      'isTrial': false,
    });
  }
}
