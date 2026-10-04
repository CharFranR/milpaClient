enum MeasureUnit {
  kilogram(0, 'kg'),
  pound(1, 'lb'),
  ton(2, 'ton'),
  unknown(-1, '—');

  const MeasureUnit(this.wireValue, this.label);

  final int wireValue;
  final String label;

  static MeasureUnit fromWire(Object? value) => switch (value) {
    0 => MeasureUnit.kilogram,
    1 => MeasureUnit.pound,
    2 => MeasureUnit.ton,
    _ => MeasureUnit.unknown,
  };
}

enum SupplyRequestStatus {
  open(0, 'Abierta'),
  cancelled(1, 'Cancelada'),
  completed(2, 'Completada'),
  expired(3, 'Expirada'),
  unknown(-1, 'Desconocida');

  const SupplyRequestStatus(this.wireValue, this.label);

  final int wireValue;
  final String label;

  static SupplyRequestStatus fromWire(Object? value) => switch (value) {
    0 => SupplyRequestStatus.open,
    1 => SupplyRequestStatus.cancelled,
    2 => SupplyRequestStatus.completed,
    3 => SupplyRequestStatus.expired,
    _ => SupplyRequestStatus.unknown,
  };

  bool get isEditable => this == SupplyRequestStatus.open;
}

class SupplyRequest {
  const SupplyRequest({
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
    this.createdAt,
    this.updatedAt,
  });

  factory SupplyRequest.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> address = json['address'] is Map
        ? Map<String, dynamic>.from(json['address'] as Map)
        : <String, dynamic>{};
    return SupplyRequest(
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
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
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
  final String? createdAt;
  final String? updatedAt;

  bool get isOpen => status.isEditable;

  double get committedAmount =>
      (totalAmount - actualAmount).clamp(0, double.infinity).toDouble();

  String get location =>
      <String>[municipality, department].where((String value) => value.isNotEmpty).join(', ');
}

class SupplyRequestDraft {
  const SupplyRequestDraft({
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
    required this.requestDeadline,
    required this.deliveryDeadline,
    required this.multipleProviders,
    required this.minAmountPerProvider,
  });

  factory SupplyRequestDraft.fromRequest(SupplyRequest request) => SupplyRequestDraft(
    productName: request.productName,
    description: request.description,
    totalAmount: request.totalAmount,
    actualAmount: request.actualAmount,
    amountUnit: request.amountUnit,
    numberOfUnits: request.numberOfUnits,
    amountPerUnit: request.amountPerUnit,
    unitOfMeasure: request.unitOfMeasure,
    department: request.department,
    municipality: request.municipality,
    addressLine: request.addressLine,
    latitude: request.latitude,
    longitude: request.longitude,
    requestDeadline: DateTime.tryParse(request.requestDeadline ?? '')?.toUtc(),
    deliveryDeadline: DateTime.tryParse(request.deliveryDeadline ?? '')?.toUtc(),
    multipleProviders: request.multipleProviders,
    minAmountPerProvider: request.minAmountPerProvider,
  );

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
  final DateTime? requestDeadline;
  final DateTime? deliveryDeadline;
  final bool multipleProviders;
  final double minAmountPerProvider;

  Map<String, dynamic> toCreateJson() => _toJson(includeActualAmount: false);

  Map<String, dynamic> toUpdateJson() => _toJson(includeActualAmount: true);

  Map<String, dynamic> _toJson({required bool includeActualAmount}) => <String, dynamic>{
    'product_name': productName,
    'total_amount': totalAmount,
    if (includeActualAmount) 'actual_amount': actualAmount,
    'amount_unit': amountUnit.wireValue,
    'number_of_units': numberOfUnits,
    'amount_per_unit': amountPerUnit,
    'unit_of_measure': unitOfMeasure.wireValue,
    'address': <String, dynamic>{
      'Department': department,
      'Municipality': municipality,
      'AddressLine': addressLine,
      'Latitude': latitude,
      'Longitude': longitude,
    },
    'request_deadline': requestDeadline?.toUtc().toIso8601String(),
    'delivery_deadline': deliveryDeadline?.toUtc().toIso8601String(),
    'description': description,
    'multiple_providers': multipleProviders,
    'min_amount_per_provider': minAmountPerProvider,
  };
}
