import 'package:flutter_application_1/core/image_url.dart';

enum CatalogSort {
  relevance('relevance'),
  priceAsc('price_asc'),
  priceDesc('price_desc'),
  proximity('proximity');

  const CatalogSort(this.wire);

  final String wire;
}

class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.name,
    required this.description,
  });

  factory CatalogCategory.fromJson(Map<String, dynamic> json) =>
      CatalogCategory(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );

  final String id;
  final String name;
  final String description;

  String get emoji => _categoryEmoji[name] ?? '🌿';
}

const Map<String, String> _categoryEmoji = <String, String>{
  'Frutales': '🍎',
  'Cítricos': '🍊',
  'Verduras': '🥦',
  'Hortalizas': '🥬',
  'Frutas': '🍅',
  'Lácteos': '🥛',
  'Carnes': '🥩',
  'Granos': '🌾',
  'Otros': '🌿',
};

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
    required this.imageUrl,
    required this.farmerId,
    required this.farmerName,
    required this.farmerVerified,
    required this.department,
    required this.municipality,
    required this.latitude,
    required this.longitude,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) => CatalogItem(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0,
    type: json['type'] as String? ?? '',
    imageUrl: json['image_url'] as String? ?? '',
    farmerId: json['farmer_id'] as String? ?? '',
    farmerName: json['farmer_name'] as String? ?? '',
    farmerVerified: json['farmer_verified'] as bool? ?? false,
    department: json['department'] as String? ?? '',
    municipality: json['municipality'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
  );

  final String id;
  final String name;
  final String description;
  final double price;
  final String type;
  final String imageUrl;
  final String farmerId;
  final String farmerName;
  final bool farmerVerified;
  final String department;
  final String municipality;
  final double latitude;
  final double longitude;

  String? get imageSrc => resolveImageSrc(imageUrl);
}

class CatalogPage {
  const CatalogPage({
    required this.results,
    required this.totalHits,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory CatalogPage.fromJson(Map<String, dynamic> json) => CatalogPage(
    results: (json['results'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(CatalogItem.fromJson)
        .toList(),
    totalHits: (json['total_hits'] as num?)?.toInt() ?? 0,
    page: (json['page'] as num?)?.toInt() ?? 1,
    pageSize: (json['page_size'] as num?)?.toInt() ?? 0,
    totalPages: (json['total_pages'] as num?)?.toInt() ?? 0,
  );

  final List<CatalogItem> results;
  final int totalHits;
  final int page;
  final int pageSize;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

String formatPrice(double value) {
  final String fixed = value.abs().toStringAsFixed(2);
  final List<String> parts = fixed.split('.');
  final String sign = value < 0 ? '-' : '';
  final String grouped = _groupThousands(parts.first);
  if (parts.last == '00') return 'C\$ $sign$grouped';
  return 'C\$ $sign$grouped,${parts.last}';
}

String _groupThousands(String digits) {
  final StringBuffer buffer = StringBuffer();
  for (int index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
