import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String paymentId;
  final String userUid;
  final String userName;
  final String userPhone;
  final String role; // 'landlord' or 'bachelor'
  final int amount; // 70 or 50
  final String trxId;
  final String senderNumber;
  final String paymentMethod; // 'bkash', 'nagad', 'rocket'
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime? date;

  PaymentModel({
    required this.paymentId,
    required this.userUid,
    required this.userName,
    required this.userPhone,
    required this.role,
    required this.amount,
    required this.trxId,
    required this.senderNumber,
    this.paymentMethod = 'bkash',
    this.status = 'pending',
    this.date,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory PaymentModel.fromMap(Map<String, dynamic> map, String docId) {
    return PaymentModel(
      paymentId: docId,
      userUid: map['userUid'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      role: map['role'] ?? 'bachelor',
      amount: map['amount'] ?? 50,
      trxId: map['trxId'] ?? '',
      senderNumber: map['senderNumber'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'bkash',
      status: map['status'] ?? 'pending',
      date: map['date'] != null
          ? (map['date'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'userUid': userUid,
      'userName': userName,
      'userPhone': userPhone,
      'role': role,
      'amount': amount,
      'trxId': trxId,
      'senderNumber': senderNumber,
      'paymentMethod': paymentMethod,
      'status': status,
      'date': date != null
          ? Timestamp.fromDate(date!)
          : FieldValue.serverTimestamp(),
    };
  }

  PaymentModel copyWith({
    String? paymentId,
    String? userUid,
    String? userName,
    String? userPhone,
    String? role,
    int? amount,
    String? trxId,
    String? senderNumber,
    String? paymentMethod,
    String? status,
    DateTime? date,
  }) {
    return PaymentModel(
      paymentId: paymentId ?? this.paymentId,
      userUid: userUid ?? this.userUid,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      role: role ?? this.role,
      amount: amount ?? this.amount,
      trxId: trxId ?? this.trxId,
      senderNumber: senderNumber ?? this.senderNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      date: date ?? this.date,
    );
  }
}
