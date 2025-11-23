import 'package:flutter/material.dart';
import '../../transactions/models/transaction_model.dart';
import '../data/report_repository.dart';

class ReportProvider extends ChangeNotifier {
  final ReportRepository _repository = ReportRepository();

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => _transactions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double _totalAmount = 0.0;
  double get totalAmount => _totalAmount;

  /// STREAM TRANSACTIONS (REAL-TIME)
  Stream<List<TransactionModel>> streamTransactions({
    required String ownerId,
    DateTime? startDate,
    DateTime? endDate,
    String? plan,
  }) {
    return _repository
        .streamTransactions(
          ownerId: ownerId,
          startDate: startDate,
          endDate: endDate,
          plan: plan,
        )
        .map((list) {
          _transactions = list;
          _calculateTotal();
          notifyListeners();
          return list;
        });
  }

  /// FETCH TRANSACTIONS ONCE
  Future<void> fetchTransactions({
    required String ownerId,
    DateTime? startDate,
    DateTime? endDate,
    String? plan,
  }) async {
    _setLoading(true);

    try {
      _transactions = await _repository.fetchTransactions(
        ownerId: ownerId,
        startDate: startDate,
        endDate: endDate,
        plan: plan,
      );
      _calculateTotal();
    } catch (e) {
      debugPrint("Error fetching report transactions: $e");
    }

    _setLoading(false);
  }

  /// ADD TRANSACTION (LOCAL ONLY — NOT SAVED)
  void addTransaction(TransactionModel txn) {
    _transactions.add(txn);
    _calculateTotal();
    notifyListeners();
  }

  /// UPDATE TRANSACTION (LOCAL ONLY — NOT SAVED)
  void updateTransaction(String id, TransactionModel updated) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      _transactions[index] = updated;
      _calculateTotal();
      notifyListeners();
    }
  }

  /// DELETE TRANSACTION (LOCAL ONLY)
  void removeTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    _calculateTotal();
    notifyListeners();
  }

  /// CALCULATE TOTAL
  void _calculateTotal() {
    _totalAmount = _transactions.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  /// LOADING HELPER
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// RESET REPORT PROVIDER
  void clearTransactions() {
    _transactions = [];
    _totalAmount = 0.0;
    notifyListeners();
  }
}
