import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../subscriptions/services/subscription_service.dart';

class DashboardProvider extends ChangeNotifier {
  final String ownerId;
  final SubscriptionService _subscriptionService;

  bool isLoading = true;

  // Data
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> txns = [];

  // Subscription info
  int remainingDays = 0;
  DateTime? expiryDate;

  DashboardProvider({required this.ownerId})
      : _subscriptionService = SubscriptionService(ownerId: ownerId);

  /// Initialize provider safely
  Future<void> init() async {
    await fetchAllData();
  }

  /// Fetch all dashboard data
  Future<void> fetchAllData() async {
    isLoading = true;
    notifyListeners();

    await Future.wait([
      _fetchMembers(),
      _fetchTransactions(),
      _fetchSubscription(),
    ]);

    isLoading = false;
    notifyListeners();
  }

  /// Fetch members from Firestore
  Future<void> _fetchMembers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('members')
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .get();

      members = snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      members = [];
      debugPrint("Error fetching members: $e");
    }
  }

  /// Fetch transactions from Firestore
  Future<void> _fetchTransactions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      txns = snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      txns = [];
      debugPrint("Error fetching transactions: $e");
    }
  }

  /// Fetch subscription info using SubscriptionService
  Future<void> _fetchSubscription() async {
    try {
      remainingDays = await _subscriptionService.remainingDays();
      expiryDate = await _subscriptionService.getExpiryDate();
    } catch (e) {
      remainingDays = 0;
      expiryDate = null;
      debugPrint("Error fetching subscription: $e");
    }
  }

  /// Renew subscription for 30 days
  Future<void> renewSubscription() async {
    await _subscriptionService.activateSubscription(30);
    await _fetchSubscription();
    notifyListeners();
  }

  /// Get birthdays today
  List<Map<String, dynamic>> getBirthdaysToday() {
    final today = DateTime.now();
    return members.where((m) {
      final dob = (m['dob'] as Timestamp?)?.toDate();
      return dob != null && dob.day == today.day && dob.month == today.month;
    }).toList();
  }

  /// Get expired members
  List<Map<String, dynamic>> getExpiredMembers() {
    final now = DateTime.now();
    return members.where((m) {
      final endDate = (m['endDate'] as Timestamp?)?.toDate();
      return endDate != null && endDate.isBefore(now);
    }).toList();
  }

  /// Dashboard summary
  Map<String, int> getSummary() {
    final now = DateTime.now();

    final active = members.where((m) {
      final endDate = (m['endDate'] as Timestamp?)?.toDate();
      return endDate != null && endDate.isAfter(now);
    }).length;

    final expiring = members.where((m) {
      final endDate = (m['endDate'] as Timestamp?)?.toDate();
      if (endDate == null) return false;
      final daysLeft = endDate.difference(now).inDays;
      return daysLeft > 0 && daysLeft <= 10;
    }).length;

    final expired = getExpiredMembers().length;

    return {
      'active': active,
      'expiring': expiring,
      'expired': expired,
      'transactions': txns.length,
    };
  }

  /// Check if trial/subscription is active
  bool get isTrialActive {
    if (expiryDate == null) return false;
    return DateTime.now().isBefore(expiryDate!);
  }
}
