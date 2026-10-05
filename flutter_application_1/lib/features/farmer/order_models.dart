import 'package:flutter_application_1/features/buyer/supply_request_models.dart';

enum OfferStatus {
  active(0, 'Esperando respuesta'),
  matched(1, 'Te eligieron'),
  rejected(2, 'No quedó'),
  withdrawn(3, 'La retiraste'),
  unknown(-1, 'Sin novedades');

  const OfferStatus(this.wireValue, this.label);

  final int wireValue;
  final String label;

  static OfferStatus fromWire(Object? value) => switch (value) {
    0 => OfferStatus.active,
    1 => OfferStatus.matched,
    2 => OfferStatus.rejected,
    3 => OfferStatus.withdrawn,
    _ => OfferStatus.unknown,
  };

  bool get isWaiting => this == OfferStatus.active;
}

class AvailableRequest {
  const AvailableRequest({
    required this.id,
    required this.buyerId,
    required this.productName,
    required this.description,
    required this.totalAmount,
    required this.actualAmount,
    required this.amountUnit,
    required this.numberOfUnits,
    required this.amountPerUnit,
    required this.unitOfMeasure,
    required this.department,
    required this.municipality,
    required this.addressLine,
    required this.latitude,
    required this.longitude,
    this.requestDeadline,
    this.deliveryDeadline,
    required this.multipleProviders,
    required this.minAmountPerProvider,
    required this.status,
  });

  factory AvailableRequest.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> address = json['address'] is Map
        ? Map<String, dynamic>.from(json['address'] as Map)
        : <String, dynamic>{};
    return AvailableRequest(
      id: json['id'] as String? ?? '',
      buyerId: json['buyer_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      actualAmount: (json['actual_amount'] as num?)?.toDouble() ?? 0,
      amountUnit: MeasureUnit.fromWire(json['amount_unit']),
      numberOfUnits: (json['number_of_units'] as num?)?.toDouble() ?? 0,
      amountPerUnit: (json['amount_per_unit'] as num?)?.toDouble() ?? 0,
      unitOfMeasure: MeasureUnit.fromWire(json['unit_of_measure']),
      department: address['Department'] as String? ?? '',
      municipality: address['Municipality'] as String? ?? '',
      addressLine: address['AddressLine'] as String? ?? '',
      latitude: (address['Latitude'] as num?)?.toDouble() ?? 0,
      longitude: (address['Longitude'] as num?)?.toDouble() ?? 0,
      requestDeadline: json['request_deadline'] as String?,
      deliveryDeadline: json['delivery_deadline'] as String?,
      multipleProviders: json['multiple_providers'] as bool? ?? false,
      minAmountPerProvider:
          (json['min_amount_per_provider'] as num?)?.toDouble() ?? 0,
      status: SupplyRequestStatus.fromWire(json['status']),
    );
  }

  final String id;
  final String buyerId;
  final String productName;
  final String description;
  final double totalAmount;
  final double actualAmount;
  final MeasureUnit amountUnit;
  final double numberOfUnits;
  final double amountPerUnit;
  final MeasureUnit unitOfMeasure;
  final String department;
  final String municipality;
  final String addressLine;
  final double latitude;
  final double longitude;
  final String? requestDeadline;
  final String? deliveryDeadline;
  final bool multipleProviders;
  final double minAmountPerProvider;
  final SupplyRequestStatus status;

  String get location => <String>[municipality, department]
      .where((String value) => value.isNotEmpty)
      .join(', ');

  DateTime? get requestDeadlineDate => DateTime.tryParse(requestDeadline ?? '');

  DateTime? get deliveryDeadlineDate =>
      DateTime.tryParse(deliveryDeadline ?? '');
}

class MyOffer {
  const MyOffer({
    required this.id,
    required this.supplierId,
    required this.supplyRequestId,
    required this.productName,
    required this.totalAmount,
    required this.measurement,
    required this.pricePerUnit,
    required this.comments,
    this.deliveryDay,
    required this.deliveryAvailable,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory MyOffer.fromJson(Map<String, dynamic> json) => MyOffer(
    id: json['id'] as String? ?? '',
    supplierId: json['supplier_id'] as String? ?? '',
    supplyRequestId: json['supply_request_id'] as String? ?? '',
    productName: json['product_name'] as String? ?? '',
    totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
    measurement: MeasureUnit.fromWire(json['measurement']),
    pricePerUnit: (json['price_per_unit'] as num?)?.toDouble() ?? 0,
    comments: json['comments'] as String? ?? '',
    deliveryDay: json['delivery_day'] as String?,
    deliveryAvailable: json['delivery_available'] as bool? ?? false,
    status: OfferStatus.fromWire(json['status']),
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
  );

  final String id;
  final String supplierId;
  final String supplyRequestId;
  final String productName;
  final double totalAmount;
  final MeasureUnit measurement;
  final double pricePerUnit;
  final String comments;
  final String? deliveryDay;
  final bool deliveryAvailable;
  final OfferStatus status;
  final String? createdAt;
  final String? updatedAt;

  DateTime? get deliveryDate => DateTime.tryParse(deliveryDay ?? '');
}

class OfferDraft {
  const OfferDraft({
    required this.supplyRequestId,
    required this.totalAmount,
    required this.pricePerUnit,
    required this.measurement,
    required this.deliveryDay,
    this.comments = '',
    this.deliveryAvailable = true,
  });

  final String supplyRequestId;
  final double totalAmount;
  final double pricePerUnit;
  final MeasureUnit measurement;
  final DateTime deliveryDay;
  final String comments;
  final bool deliveryAvailable;

  Map<String, dynamic> toJson() => _json(includeRequestId: true);

  Map<String, dynamic> toUpdateJson() => _json(includeRequestId: false);

  Map<String, dynamic> _json({required bool includeRequestId}) =>
      <String, dynamic>{
        if (includeRequestId) 'supply_request_id': supplyRequestId,
        'total_amount': totalAmount,
        'price_per_unit': pricePerUnit,
        'measurement': measurement.wireValue,
        'comments': comments.trim(),
        'delivery_day': deliveryDay.toUtc().toIso8601String(),
        'delivery_available': deliveryAvailable,
      };
}
