
class PostModel {
  final String postId;
  final String ownerUid;
  final String title;
  final double rent;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> images;
  final String? videoUrl;
  final int seatCount;
  final String? seatDescription; // Custom input e.g. "1 Room & 2 Seats"
  final String division;
  final String district;
  final String bachelorType; // 'male', 'female', 'both'
  final String preferredTenant; // 'Student', 'Job', 'Student / Job holder'
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
    this.videoUrl,
    required this.seatCount,
    this.seatDescription,
    required this.division,
    required this.district,
    required this.bachelorType,
    this.preferredTenant = 'Student / Job holder',
    required this.facilities,
    this.isAvailable = true,
    this.createdAt,
    this.ownerPhone,
    this.paymentStatus = 'approved',
    this.isPublished = true,
    this.paymentTrxId,
    this.senderNumber,
  });

  String get displaySeats {
    if (seatDescription != null && seatDescription!.trim().isNotEmpty) {
      return seatDescription!.trim();
    }
    return '$seatCount ${seatCount == 1 ? "Seat" : "Seats"}';
  }

  factory PostModel.fromMap(Map<String, dynamic> map, String docId) {
    // Helper: parse images/facilities from either List or JSON string
    List<String> parseList(dynamic val) {
      if (val == null) return [];
      if (val is List) return List<String>.from(val);
      if (val is String && val.isNotEmpty) {
        try {
          final decoded = val.replaceAll(RegExp(r'^\[|\]$'), '').split(',');
          return decoded.map((e) => e.trim().replaceAll('"', '')).where((e) => e.isNotEmpty).toList();
        } catch (_) { return []; }
      }
      return [];
    }

    // Helper: parse DateTime from String, Timestamp, or null
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String && val.isNotEmpty) {
        try { return DateTime.parse(val); } catch (_) { return null; }
      }
      // Firebase Timestamp (legacy)
      try {
        if (val.runtimeType.toString().contains('Timestamp')) {
          return (val as dynamic).toDate() as DateTime;
        }
      } catch (_) {}
      return null;
    }

    // Helper: safely parse double (PostgreSQL NUMERIC → String)
    double parseDouble(dynamic val, double fallback) {
      if (val == null) return fallback;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? fallback;
      return fallback;
    }

    // Helper: safely parse int from String, int, or double
    int parseInt(dynamic val, int fallback) {
      if (val == null) return fallback;
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    return PostModel(
      postId: docId,
      ownerUid: (map['owner_uid'] ?? map['ownerUid'])?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      rent: parseDouble(map['rent'], 0.0),
      address: map['address']?.toString() ?? '',
      latitude: parseDouble(map['latitude'] ?? map['lat'], 23.8103),
      longitude: parseDouble(map['longitude'] ?? map['lng'], 90.4125),
      images: parseList(map['images']),
      videoUrl: (map['video_url'] ?? map['videoUrl'])?.toString(),
      seatCount: parseInt(map['seat_count'] ?? map['seatCount'], 1),
      seatDescription: (map['seat_description'] ?? map['seatDescription'])?.toString(),
      division: map['division']?.toString() ?? 'Dhaka',
      district: map['district']?.toString() ?? 'Dhaka',
      bachelorType: (map['bachelor_type'] ?? map['bachelorType'])?.toString() ?? 'male',
      preferredTenant: (map['preferred_tenant'] ?? map['preferredTenant'])?.toString() ?? 'Student / Job holder',
      facilities: parseList(map['facilities']),
      isAvailable: map['is_available'] ?? map['isAvailable'] ?? true,
      createdAt: parseDate(map['created_at'] ?? map['createdAt']),
      ownerPhone: (map['owner_phone'] ?? map['ownerPhone'])?.toString(),
      paymentStatus: (map['payment_status'] ?? map['paymentStatus'])?.toString() ?? 'approved',
      isPublished: map['is_published'] ?? map['isPublished'] ?? true,
      paymentTrxId: (map['payment_trx_id'] ?? map['paymentTrxId'])?.toString(),
      senderNumber: (map['sender_number'] ?? map['senderNumber'])?.toString(),
    );
  }

  /// JSON-safe map for REST API (Dio/PostgreSQL)
  Map<String, dynamic> toMap() {
    return {
      'post_id': postId,
      'owner_uid': ownerUid,
      'title': title,
      'rent': rent,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'videoUrl': videoUrl,
      'seatCount': seatCount,
      'seatDescription': seatDescription,
      'division': division,
      'district': district,
      'bachelorType': bachelorType,
      'preferredTenant': preferredTenant,
      'facilities': facilities,
      'isAvailable': isAvailable,
      'created_at': createdAt?.toIso8601String(),
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
    String? videoUrl,
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
      videoUrl: videoUrl ?? this.videoUrl,
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
