import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String bookingId;
  final String postId;
  final String bachelorUid;
  final String landlordUid;
  final String paymentStatus; // 'pending', 'approved', 'rejected'
  final String trxId;
  final String senderNumber;
  final bool isUnlocked;
  final DateTime? createdAt;
  final String? bachelorName;
  final String? bachelorPhone;

  BookingModel({
    required this.bookingId,
    required this.postId,
    required this.bachelorUid,
    required this.landlordUid,
    this.paymentStatus = 'pending',
    required this.trxId,
    required this.senderNumber,
    this.isUnlocked = false,
    this.createdAt,
    this.bachelorName,
    this.bachelorPhone,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    return BookingModel(
      bookingId: docId,
      postId: map['postId'] ?? '',
      bachelorUid: map['bachelorUid'] ?? '',
      landlordUid: map['landlordUid'] ?? '',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      trxId: map['trxId'] ?? '',
      senderNumber: map['senderNumber'] ?? '',
      isUnlocked: map['isUnlocked'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      bachelorName: map['bachelorName']?.toString(),
      bachelorPhone: map['bachelorPhone']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'postId': postId,
      'bachelorUid': bachelorUid,
      'landlordUid': landlordUid,
      'paymentStatus': paymentStatus,
      'trxId': trxId,
      'senderNumber': senderNumber,
      'isUnlocked': isUnlocked,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (bachelorName != null) 'bachelorName': bachelorName,
      if (bachelorPhone != null) 'bachelorPhone': bachelorPhone,
    };
  }

  BookingModel copyWith({
    String? bookingId,
    String? postId,
    String? bachelorUid,
    String? landlordUid,
    String? paymentStatus,
    String? trxId,
    String? senderNumber,
    bool? isUnlocked,
    DateTime? createdAt,
    String? bachelorName,
    String? bachelorPhone,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      postId: postId ?? this.postId,
      bachelorUid: bachelorUid ?? this.bachelorUid,
      landlordUid: landlordUid ?? this.landlordUid,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      trxId: trxId ?? this.trxId,
      senderNumber: senderNumber ?? this.senderNumber,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      createdAt: createdAt ?? this.createdAt,
      bachelorName: bachelorName ?? this.bachelorName,
      bachelorPhone: bachelorPhone ?? this.bachelorPhone,
    );
  }
}

