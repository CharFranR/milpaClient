import 'package:flutter_application_1/core/image_url.dart';

class FarmerProduct {
  const FarmerProduct({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.variety,
    required this.unitOfMeasureId,
    required this.quantityAvailable,
    required this.isActive,
    required this.categoryId,
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
  });

  factory FarmerProduct.fromJson(Map<String, dynamic> json) => FarmerProduct(
    id: json['id'] as String? ?? '',
    userId: json['user_id'] as String? ?? '',
    type: (json['type'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0,
    imageUrl: json['image_url'] as String? ?? '',
    variety: json['variety'] as String? ?? '',
    unitOfMeasureId: json['unit_of_measure_id'] as String? ?? '',
    quantityAvailable: (json['quantity_available'] as num?)?.toDouble() ?? 0,
    isActive: json['is_active'] as bool? ?? true,
    categoryId: json['category_id'] as String? ?? '',
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
    expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
  );

  final String id;
  final String userId;
  final int type;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String variety;
  final String unitOfMeasureId;
  final double quantityAvailable;
  final bool isActive;
  final String categoryId;
  final String? createdAt;
  final String? updatedAt;
  final DateTime? expiresAt;

  String? get imageSrc => resolveImageSrc(imageUrl);

  bool get isExpired {
    final DateTime? expiresAt = this.expiresAt;
    return expiresAt != null && !expiresAt.isAfter(DateTime.now());
  }

  bool get isHidden => !isActive || isExpired;
}

class FarmerCategory {
  const FarmerCategory({
    required this.id,
    required this.name,
    required this.defaultUnitOfMeasureId,
    this.defaultExpiryDays,
  });

  factory FarmerCategory.fromJson(Map<String, dynamic> json) => FarmerCategory(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    defaultUnitOfMeasureId: json['default_unit_of_measure_id'] as String? ?? '',
    defaultExpiryDays: (json['default_expiry_days'] as num?)?.toInt(),
  );

  final String id;
  final String name;
  final String defaultUnitOfMeasureId;
  final int? defaultExpiryDays;
}

class ProductDraft {
  const ProductDraft({
    required this.userId,
    required this.name,
    required this.variety,
    required this.unitOfMeasureId,
    required this.quantityAvailable,
    required this.categoryId,
    required this.description,
    required this.price,
    required this.expiresAt,
    this.imageUrl,
  });

  final String userId;
  final String name;
  final String variety;
  final String unitOfMeasureId;
  final double quantityAvailable;
  final String categoryId;
  final String description;
  final double price;
  final DateTime expiresAt;
  final String? imageUrl;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'user_id': userId,
    'name': name.trim(),
    'type': 0,
    'variety': variety.trim().isEmpty ? 'General' : variety.trim(),
    'unit_of_measure_id': unitOfMeasureId,
    'quantity_available': quantityAvailable,
    'category_id': categoryId,
    if (description.trim().isNotEmpty) 'description': description.trim(),
    if ((imageUrl ?? '').isNotEmpty) 'image_url': imageUrl,
    'price': price,
    'expires_at': expiresAt.toUtc().toIso8601String(),
  };
}
