import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  final String id;
  final String ownerId;
  final String name;
  final String? phone;
  final String? email;
  final String? photoPath;
  final String? photoUrl;
  final double fee;
  final String plan;
  final DateTime? dob;
  final DateTime startDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int durationDays; // Membership duration in days

  MemberModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.phone,
    this.email,
    this.photoPath,
    this.photoUrl,
    this.fee = 0,
    this.plan = '1 Month',
    this.dob,
    required this.startDate,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.durationDays = 30, // default 1 month
  });

  /// Create MemberModel from Firestore Document
  factory MemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Timestamp toDate(dynamic timestamp) {
      if (timestamp == null) return Timestamp.now();
      if (timestamp is Timestamp) return timestamp;
      return Timestamp.fromMillisecondsSinceEpoch(timestamp);
    }

    return MemberModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      email: data['email'],
      photoPath: data['photoPath'],
      photoUrl: data['photoUrl'],
      fee: (data['fee'] ?? 0).toDouble(),
      plan: data['plan'] ?? '1 Month',
      dob: data['dob'] != null ? toDate(data['dob']).toDate() : null,
      startDate: toDate(data['startDate']).toDate(),
      notes: data['notes'],
      createdAt: toDate(data['createdAt']).toDate(),
      updatedAt: data['updatedAt'] != null ? toDate(data['updatedAt']).toDate() : null,
      durationDays: data['durationDays'] ?? 30,
    );
  }

  /// Convert MemberModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'phone': phone,
      'email': email,
      'photoPath': photoPath,
      'photoUrl': photoUrl,
      'fee': fee,
      'plan': plan,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
      'startDate': Timestamp.fromDate(startDate),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'durationDays': durationDays,
    };
  }

  /// CopyWith method for easy updates
  MemberModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? phone,
    String? email,
    String? photoPath,
    String? photoUrl,
    double? fee,
    String? plan,
    DateTime? dob,
    DateTime? startDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? durationDays,
  }) {
    return MemberModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoPath: photoPath ?? this.photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
      fee: fee ?? this.fee,
      plan: plan ?? this.plan,
      dob: dob ?? this.dob,
      startDate: startDate ?? this.startDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      durationDays: durationDays ?? this.durationDays,
    );
  }

  /// ------------------ Membership Helper Methods ------------------

  /// Calculate membership end date
  DateTime calculateMembershipEnd() {
    return startDate.add(Duration(days: durationDays));
  }

  /// Check if membership is expired
  bool isExpired() {
    return DateTime.now().isAfter(calculateMembershipEnd());
  }

  /// Check if membership is expiring soon (default 7 days threshold)
  bool isExpiringSoon({int daysThreshold = 7}) {
    final end = calculateMembershipEnd();
    final now = DateTime.now();
    return !isExpired() && end.difference(now).inDays <= daysThreshold;
  }

  /// Get number of days remaining (negative if expired)
  int getDaysRemaining() {
    return calculateMembershipEnd().difference(DateTime.now()).inDays;
  }

  /// Get membership status text
  String getMembershipStatus() {
    if (isExpired()) return 'Expired';
    if (isExpiringSoon()) return 'Expiring Soon';
    return 'Active';
  }
}
