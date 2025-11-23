import 'package:cloud_firestore/cloud_firestore.dart';
import '../../transactions/models/transaction_model.dart';

class ReportRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath = 'transactions';

  /// Stream transactions filtered by ownerId, optional date range, and plan
  Stream<List<TransactionModel>> streamTransactions({
    required String ownerId,
    DateTime? startDate,
    DateTime? endDate,
    String? plan,
  }) {
    Query query = _firestore
        .collection(collectionPath)
        .where('ownerId', isEqualTo: ownerId);

    if (plan != null && plan.isNotEmpty) {
      query = query.where('plan', isEqualTo: plan);
    }

    if (startDate != null) {
      query = query.where(
          'membershipStartDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where(
          'membershipEndDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    query = query.orderBy('membershipStartDate', descending: false);

    return query.snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList(),
    );
  }

  /// Fetch transactions once (non-stream) with optional filters
  Future<List<TransactionModel>> fetchTransactions({
    required String ownerId,
    DateTime? startDate,
    DateTime? endDate,
    String? plan,
  }) async {
    Query query = _firestore
        .collection(collectionPath)
        .where('ownerId', isEqualTo: ownerId);

    if (plan != null && plan.isNotEmpty) {
      query = query.where('plan', isEqualTo: plan);
    }

    if (startDate != null) {
      query = query.where(
          'membershipStartDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where(
          'membershipEndDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    query = query.orderBy('membershipStartDate', descending: false);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
  }

  /// Calculate total transaction amount for given filters
  Future<double> calculateTotalAmount({
    required String ownerId,
    DateTime? startDate,
    DateTime? endDate,
    String? plan,
  }) async {
    final transactions = await fetchTransactions(
      ownerId: ownerId,
      startDate: startDate,
      endDate: endDate,
      plan: plan,
    );
    return transactions.fold<double>(
        0.0, (sum, tx) => sum + (tx.amount ?? 0.0)); // use ?? 0.0 if nullable
  }

}
