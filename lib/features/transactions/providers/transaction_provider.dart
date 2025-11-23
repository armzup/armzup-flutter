// lib/features/transactions/providers/transaction_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../transactions/models/transaction_model.dart';
import '../data/transaction_respository.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();

  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => _transactions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- Filter Fields ---
  String filterStatus = 'all';
  String filterPaymentMethod = 'all';
  DateTime? filterStartDate;
  DateTime? filterEndDate;

  // --- Revenue Getters ---
  double get todayRevenue {
    final today = DateTime.now();
    return _transactions
        .where((txn) =>
            txn.createdAt.year == today.year &&
            txn.createdAt.month == today.month &&
            txn.createdAt.day == today.day)
        .fold(0.0, (sum, txn) => sum + txn.amount);
  }

  double get monthlyRevenue {
    final now = DateTime.now();
    return _transactions
        .where((txn) =>
            txn.createdAt.year == now.year && txn.createdAt.month == now.month)
        .fold(0.0, (sum, txn) => sum + txn.amount);
  }

  // --- Set Filters ---
  void setFilters({
    String? status,
    String? paymentMethod,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (status != null) filterStatus = status;
    if (paymentMethod != null) filterPaymentMethod = paymentMethod;
    filterStartDate = startDate;
    filterEndDate = endDate;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _transactions = _allTransactions.where((txn) {
      bool statusMatch = filterStatus == 'all' ||
          (filterStatus == 'completed' && txn.isPaid) ||
          (filterStatus == 'pending' && !txn.isPaid) ||
          (filterStatus == 'failed' && txn.isFailed);

      bool paymentMatch = filterPaymentMethod == 'all' ||
          txn.paymentMethod.toLowerCase() ==
              filterPaymentMethod.toLowerCase();

      bool startDateMatch = filterStartDate == null ||
          txn.createdAt.isAfter(
              filterStartDate!.subtract(const Duration(days: 1)));
      bool endDateMatch = filterEndDate == null ||
          txn.createdAt.isBefore(filterEndDate!.add(const Duration(days: 1)));

      return statusMatch && paymentMatch && startDateMatch && endDateMatch;
    }).toList();
  }

  // --- Stream transactions for real-time updates ---
  Stream<List<TransactionModel>> streamTransactions(String ownerId) {
    return _repository.streamTransactions(ownerId).map((list) {
      _allTransactions = list;
      _applyFilters();
      notifyListeners();
      return _transactions;
    });
  }

  // --- Fetch transactions once ---
  Future<void> fetchTransactions(String ownerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _allTransactions = await _repository.streamTransactions(ownerId).first;
      _applyFilters();
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- Add new transaction ---
  Future<void> addTransaction(TransactionModel transaction) async {
    await _repository.addTransaction(transaction);
    await fetchTransactions(transaction.ownerId);
  }

  // --- Update existing transaction ---
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _repository.updateTransaction(transaction);
    await fetchTransactions(transaction.ownerId);
  }

  // --- Delete transaction ---
  Future<void> deleteTransaction(String id, String ownerId) async {
    await _repository.deleteTransaction(id);
    await fetchTransactions(ownerId);
  }

  // --- Simulate UPI Payment ---
  Future<bool> payViaUPI({
    required String memberName,
    required double amount,
    required String upiId,
    required String plan,
    String? photoPath,
    DateTime? dob,
    DateTime? membershipStartDate,
    String? transactionNote,
    String ownerId = '', // optional ownerId to save transaction
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      // fallback to current logged-in user if ownerId not provided
      final ownerIdFinal =
          ownerId.isNotEmpty ? ownerId : FirebaseAuth.instance.currentUser?.uid ?? '';

      final transaction = TransactionModel(
        id: '', // repository should generate unique ID (add uses auto-id)
        ownerId: ownerIdFinal,
        memberId: null,
        memberName: memberName,
        memberPhone: null,
        photoUrl: null,
        photoPath: photoPath,
        plan: plan,
        amount: amount,
        paymentMethod: 'UPI',
        membershipStartDate: membershipStartDate ?? DateTime.now(),
        membershipEndDate:
            TransactionModel.calculateEndDate(membershipStartDate ?? DateTime.now(), plan),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: transactionNote,
        isPaid: true,
        dob: dob,
        isFailed: false,
      );

      await addTransaction(transaction);
      return true;
    } catch (e) {
      debugPrint('UPI Payment Error: $e');
      return false;
    }
  }
}
