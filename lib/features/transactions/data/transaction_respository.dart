import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath = 'transactions';

  Future<void> addTransaction(TransactionModel transaction) async {
    final now = DateTime.now();

    await _firestore.collection(collectionPath).add({
      ...transaction.toMap(),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _firestore.collection(collectionPath).doc(transaction.id).update({
      ...transaction.toMap(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteTransaction(String id) async {
    await _firestore.collection(collectionPath).doc(id).delete();
  }

  Stream<List<TransactionModel>> streamTransactions(String ownerId) {
    return _firestore
        .collection(collectionPath)
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList());
  }

  Future<TransactionModel?> getTransactionById(String id) async {
    final doc = await _firestore.collection(collectionPath).doc(id).get();
    if (!doc.exists) return null;
    return TransactionModel.fromFirestore(doc);
  }
}
