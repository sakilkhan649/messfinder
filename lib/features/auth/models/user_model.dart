import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String role; // 'landlord' or 'bachelor' or 'admin'
  final bool isPaid;
  final DateTime? createdAt;
  final String? photoUrl;
  final String? trxId; // পেমেন্ট ভেরিফিকেশনের TrxID

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    this.isPaid = false,
    this.createdAt,
    this.photoUrl,
    this.trxId,
  });

  bool get isLandlord => role == 'landlord';
  bool get isBachelor => role == 'bachelor';
  bool get isAdmin => role == 'admin';

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId,
      name: map['name'] ?? map['userName'] ?? map['displayName'] ?? '',
      phone: map['phone'] ?? map['phoneNumber'] ?? map['userPhone'] ?? map['mobile'] ?? '',
      role: map['role'] ?? 'bachelor',
      isPaid: map['isPaid'] ?? false,
      trxId: map['trxId'] ?? map['paymentTrxId'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      photoUrl: map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'role': role,
      'isPaid': isPaid,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (trxId != null && trxId!.isNotEmpty) 'trxId': trxId,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? phone,
    String? role,
    bool? isPaid,
    DateTime? createdAt,
    String? photoUrl,
    String? trxId,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      trxId: trxId ?? this.trxId,
    );
  }
}
