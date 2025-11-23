import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String ownerId;
  final String? memberId; // Optional if only name is stored
  final String memberName;
  final String? memberPhone;
  final String? photoUrl;  // Cloud storage URL
  final String? photoPath; // Local device path
  final String plan;
  final double amount;
  final String paymentMethod; // 'Cash', 'UPI', 'Card', 'Online'
  final DateTime membershipStartDate;
  final DateTime membershipEndDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final bool isPaid;
  final DateTime? dob;
  final bool isFailed;

  TransactionModel({
    required this.id,
    required this.ownerId,
    this.memberId,
    required this.memberName,
    this.memberPhone,
    this.photoUrl,
    this.photoPath,
    required this.plan,
    required this.amount,
    required this.paymentMethod,
    required this.membershipStartDate,
    required this.membershipEndDate,
    required this.createdAt,
    this.updatedAt,
    this.notes,
    this.isPaid = true,
    this.dob,
    this.isFailed = false,
  });

  /// ✅ Helper for safely parsing Firestore timestamps
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Firestore → TransactionModel
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return TransactionModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      memberId: data['memberId'],
      memberName: data['memberName'] ?? '',
      memberPhone: data['memberPhone'],
      photoUrl: data['photoUrl'],
      photoPath: data['photoPath'],
      plan: data['plan'] ?? '1 Month',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      membershipStartDate: _parseTimestamp(data['membershipStartDate']),
      membershipEndDate: _parseTimestamp(data['membershipEndDate']),
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? _parseTimestamp(data['updatedAt']) : null,
      notes: data['notes'],
      isPaid: data['isPaid'] ?? true,
      dob: data['dob'] != null ? _parseTimestamp(data['dob']) : null,
      isFailed: data['isFailed'] ?? false,
    );
  }

  /// TransactionModel → Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'memberId': memberId,
      'memberName': memberName,
      'memberPhone': memberPhone,
      'photoUrl': photoUrl,
      'photoPath': photoPath,
      'plan': plan,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'membershipStartDate': Timestamp.fromDate(membershipStartDate),
      'membershipEndDate': Timestamp.fromDate(membershipEndDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'notes': notes,
      'isPaid': isPaid,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
      'isFailed': isFailed,
    };
  }

  /// Utility: Calculate membership end date from plan
  static DateTime calculateEndDate(DateTime startDate, String plan) {
    final planDays = {
      '1 Month': 30,
      '3 Months': 90,
      '6 Months': 180,
      '12 Months': 365,
    };
    return startDate.add(Duration(days: planDays[plan] ?? 30));
  }

  /// ✅ Easy update
  TransactionModel copyWith({
    String? memberName,
    String? memberPhone,
    String? photoUrl,
    String? photoPath,
    String? plan,
    double? amount,
    String? paymentMethod,
    DateTime? membershipStartDate,
    DateTime? membershipEndDate,
    DateTime? updatedAt,
    String? notes,
    bool? isPaid,
    DateTime? dob,
    bool? isFailed,
  }) {
    return TransactionModel(
      id: id,
      ownerId: ownerId,
      memberId: memberId,
      memberName: memberName ?? this.memberName,
      memberPhone: memberPhone ?? this.memberPhone,
      photoUrl: photoUrl ?? this.photoUrl,
      photoPath: photoPath ?? this.photoPath,
      plan: plan ?? this.plan,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      membershipStartDate: membershipStartDate ?? this.membershipStartDate,
      membershipEndDate: membershipEndDate ?? this.membershipEndDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      isPaid: isPaid ?? this.isPaid,
      dob: dob ?? this.dob,
      isFailed: isFailed ?? this.isFailed,
    );
  }
}
