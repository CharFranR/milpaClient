import 'package:flutter_application_1/core/image_url.dart';

class OfferingDetail {
  const OfferingDetail({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.latitude,
    this.longitude,
  });

  factory OfferingDetail.fromJson(Map<String, dynamic> json) => OfferingDetail(
    id: json['id'] as String? ?? '',
    userId: json['user_id'] as String? ?? '',
    type: (json['type'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0,
    imageUrl: json['image_url'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );

  final String id;
  final String userId;
  final int type;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final double? latitude;
  final double? longitude;

  String? get imageSrc => resolveImageSrc(imageUrl);
}

class SellerProfile {
  const SellerProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.department,
    required this.municipality,
  });

  factory SellerProfile.fromJson(Map<String, dynamic> json) => SellerProfile(
    id: json['id'] as String? ?? '',
    firstName: json['first_name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
    role: (json['role'] as num?)?.toInt() ?? 0,
    department: json['department'] as String? ?? '',
    municipality: json['municipality'] as String? ?? '',
  );

  final String id;
  final String firstName;
  final String lastName;
  final int role;
  final String department;
  final String municipality;

  String get fullName => '$firstName $lastName'.trim();
}

class RatingSummary {
  const RatingSummary({required this.average, required this.count});

  factory RatingSummary.fromJson(Map<String, dynamic> json) => RatingSummary(
    average: (json['average'] as num?)?.toDouble() ?? 0,
    count: (json['count'] as num?)?.toInt() ?? 0,
  );

  final double average;
  final int count;

  bool get hasReviews => count > 0;
}
