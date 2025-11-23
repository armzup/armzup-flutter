import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';

class MemberRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath = 'members';

  String newId() {
    return _firestore.collection(collectionPath).doc().id;
  }

  Future<void> addMember(MemberModel member) async {
    final now = DateTime.now();
    await _firestore.collection(collectionPath).doc(member.id).set({
      ...member.toMap(), // Make sure toMap includes photoUrl
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> updateMember(MemberModel member) async {
    await _firestore.collection(collectionPath).doc(member.id).update({
      ...member.toMap(), // Ensure photoUrl is included
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteMember(String id) async {
    await _firestore.collection(collectionPath).doc(id).delete();
  }

  Stream<List<MemberModel>> streamMembers(String ownerId) {
    return _firestore
        .collection(collectionPath)
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => MemberModel.fromFirestore(doc)).toList());
  }
}
