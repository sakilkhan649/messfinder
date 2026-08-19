
class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String role; // 'bachelor', 'landlord', 'admin'
  final String status; // 'active', 'suspended', 'banned'
  final bool isPaid; // 🆓 Free Launch: always true. Note: restore gate for in-app purchase
  final DateTime? createdAt;
  final String? photoUrl;
  final String? trxId;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.email = '',
    required this.role,
    this.status = 'active',
    this.isPaid = true, // 🆓 Free Launch: default true. Note: set false when in-app purchase is live
    this.createdAt,
    this.photoUrl,
    this.trxId,
  });

  bool get isUser => role != 'admin';
  bool get isAdmin => role == 'admin';

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String && val.isNotEmpty) {
        try { return DateTime.parse(val); } catch (_) { return null; }
      }
      return null;
    }

    return UserModel(
      uid: docId.isNotEmpty ? docId : (map['uid']?.toString() ?? ''),
      name: map['name'] ?? map['userName'] ?? map['displayName'] ?? '',
      phone: map['phone'] ?? map['phoneNumber'] ?? map['userPhone'] ?? map['mobile'] ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role'] ?? 'bachelor',
      status: map['status']?.toString() ?? 'active',
      isPaid: true, // 🆓 Free Launch: always true. Note: restore → map['isPaid'] ?? (map['status'] == 'active')
      trxId: map['trxId'] ?? map['paymentTrxId'],
      createdAt: parseDate(map['created_at'] ?? map['createdAt']),
      photoUrl: map['profile_image'] ?? map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'status': status,
      'profile_image': photoUrl,
      'photoUrl': photoUrl,
      if (trxId != null && trxId!.isNotEmpty) 'trxId': trxId,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? phone,
    String? email,
    String? role,
    String? status,
    bool? isPaid,
    DateTime? createdAt,
    String? photoUrl,
    String? trxId,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      trxId: trxId ?? this.trxId,
    );
  }
}
