import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String ownerUid;
  final String title;
  final double rent;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> images;
  final int seatCount;
  final String? seatDescription; // Custom input e.g. "1 Room & 2 Seats"
  final String division;
  final String district;
  final String bachelorType; // 'male', 'female', 'both'
  final String? _preferredTenant; // 'Student', 'Job', 'Student / Job holder'
  String get preferredTenant => _preferredTenant ?? 'Student / Job holder';
  final List<String> facilities;
  final bool isAvailable;
  final DateTime? createdAt;
  final String? ownerPhone;
  final String paymentStatus; // 'pending', 'approved', 'rejected'
  final bool isPublished;
  final String? paymentTrxId;
  final String? senderNumber;

  PostModel({
    required this.postId,
    required this.ownerUid,
    required this.title,
    required this.rent,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.seatCount,
    this.seatDescription,
    required this.division,
    required this.district,
    required this.bachelorType,
    String? preferredTenant = 'Student / Job holder',
    required this.facilities,
    this.isAvailable = true,
    this.createdAt,
    this.ownerPhone,
    this.paymentStatus = 'approved',
    this.isPublished = true,
    this.paymentTrxId,
    this.senderNumber,
  }) : _preferredTenant = preferredTenant; // ignore: prefer_initializing_formals

  String get displaySeats {
    if (seatDescription != null && seatDescription!.trim().isNotEmpty) {
      return seatDescription!.trim();
    }
    return '$seatCount ${seatCount == 1 ? "Seat" : "Seats"}';
  }

  factory PostModel.fromMap(Map<String, dynamic> map, String docId) {
    return PostModel(
      postId: docId,
      ownerUid: map['ownerUid']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      rent: (map['rent'] ?? 0).toDouble(),
      address: map['address']?.toString() ?? '',
      latitude: (map['latitude'] ?? 23.8103).toDouble(),
      longitude: (map['longitude'] ?? 90.4125).toDouble(),
      images: List<String>.from(map['images'] ?? []),
      seatCount: map['seatCount'] ?? 1,
      seatDescription: map['seatDescription']?.toString(),
      division: map['division']?.toString() ?? 'Dhaka',
      district: map['district']?.toString() ?? 'Dhaka',
      bachelorType: map['bachelorType']?.toString() ?? 'male',
      preferredTenant: map['preferredTenant']?.toString() ?? 'Student / Job holder',
      facilities: List<String>.from(map['facilities'] ?? []),
      isAvailable: map['isAvailable'] ?? true,
      createdAt: map['createdAt'] != null && map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      ownerPhone: map['ownerPhone']?.toString(),
      paymentStatus: map['paymentStatus']?.toString() ?? 'approved',
      isPublished: map['isPublished'] ?? true,
      paymentTrxId: map['paymentTrxId']?.toString(),
      senderNumber: map['senderNumber']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'ownerUid': ownerUid,
      'title': title,
      'rent': rent,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'seatCount': seatCount,
      'seatDescription': seatDescription,
      'division': division,
      'district': district,
      'bachelorType': bachelorType,
      'preferredTenant': preferredTenant,
      'facilities': facilities,
      'isAvailable': isAvailable,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'ownerPhone': ownerPhone,
      'paymentStatus': paymentStatus,
      'isPublished': isPublished,
      'paymentTrxId': paymentTrxId,
      'senderNumber': senderNumber,
    };
  }

  PostModel copyWith({
    String? postId,
    String? ownerUid,
    String? title,
    double? rent,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? images,
    int? seatCount,
    String? seatDescription,
    String? division,
    String? district,
    String? bachelorType,
    String? preferredTenant,
    List<String>? facilities,
    bool? isAvailable,
    String? ownerPhone,
    String? paymentStatus,
    bool? isPublished,
    String? paymentTrxId,
    String? senderNumber,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      ownerUid: ownerUid ?? this.ownerUid,
      title: title ?? this.title,
      rent: rent ?? this.rent,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      images: images ?? this.images,
      seatCount: seatCount ?? this.seatCount,
      seatDescription: seatDescription ?? this.seatDescription,
      division: division ?? this.division,
      district: district ?? this.district,
      bachelorType: bachelorType ?? this.bachelorType,
      preferredTenant: preferredTenant ?? this.preferredTenant,
      facilities: facilities ?? this.facilities,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isPublished: isPublished ?? this.isPublished,
      paymentTrxId: paymentTrxId ?? this.paymentTrxId,
      senderNumber: senderNumber ?? this.senderNumber,
    );
  }
}
