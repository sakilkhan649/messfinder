class ProductModel {
  final String? productId;
  final String sellerUid;
  final String? sellerName;
  final String? sellerImage;
  final String? sellerPhone;
  final String title;
  final String description;
  final double price;
  final String condition;
  final String category;
  final List<String> images;
  final String division;
  final String district;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    this.productId,
    required this.sellerUid,
    this.sellerName,
    this.sellerImage,
    this.sellerPhone,
    required this.title,
    this.description = '',
    required this.price,
    this.condition = 'used',
    this.category = 'Others',
    this.images = const [],
    this.division = 'Dhaka',
    this.district = 'Dhaka',
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['product_id']?.toString(),
      sellerUid: json['seller_uid'] ?? '',
      sellerName: json['seller_name'],
      sellerImage: json['seller_image'],
      sellerPhone: json['seller_phone'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] != null ? double.tryParse(json['price'].toString()) ?? 0.0 : 0.0,
      condition: json['condition'] ?? 'used',
      category: json['category'] ?? 'Others',
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      division: json['division'] ?? 'Dhaka',
      district: json['district'] ?? 'Dhaka',
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'seller_uid': sellerUid,
      'title': title,
      'description': description,
      'price': price,
      'condition': condition,
      'category': category,
      'images': images,
      'division': division,
      'district': district,
      'status': status,
    };
  }

  ProductModel copyWith({
    String? productId,
    String? sellerUid,
    String? sellerName,
    String? sellerImage,
    String? sellerPhone,
    String? title,
    String? description,
    double? price,
    String? condition,
    String? category,
    List<String>? images,
    String? division,
    String? district,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      sellerUid: sellerUid ?? this.sellerUid,
      sellerName: sellerName ?? this.sellerName,
      sellerImage: sellerImage ?? this.sellerImage,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      condition: condition ?? this.condition,
      category: category ?? this.category,
      images: images ?? this.images,
      division: division ?? this.division,
      district: district ?? this.district,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
