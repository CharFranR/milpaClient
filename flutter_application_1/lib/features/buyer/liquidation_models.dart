enum LiquidationVisibility {
  public('public', 'Todos los compradores'),
  wholesale('wholesale', 'Solo mayoristas'),
  wholesaleRetail('wholesale_retail', 'Solo detallistas'),
  wholesaleCorporate('wholesale_corporate', 'Solo corporativos'),
  unknown('', 'Sin visibilidad definida');

  const LiquidationVisibility(this.wire, this.label);

  final String wire;
  final String label;

  static LiquidationVisibility fromWire(Object? value) => switch (value) {
    'public' => LiquidationVisibility.public,
    'wholesale' => LiquidationVisibility.wholesale,
    'wholesale_retail' => LiquidationVisibility.wholesaleRetail,
    'wholesale_corporate' => LiquidationVisibility.wholesaleCorporate,
    _ => LiquidationVisibility.unknown,
  };
}

enum LiquidationStatus {
  open(0, 'Disponible'),
  closed(1, 'Cerrado'),
  expired(2, 'Expirado'),
  assigned(3, 'Asignado'),
  unknown(-1, 'Desconocido');

  const LiquidationStatus(this.wireValue, this.label);

  final int wireValue;
  final String label;

  static LiquidationStatus fromWire(Object? value) => switch (value) {
    0 => LiquidationStatus.open,
    1 => LiquidationStatus.closed,
    2 => LiquidationStatus.expired,
    3 => LiquidationStatus.assigned,
    _ => LiquidationStatus.unknown,
  };

  bool get isOpen => this == LiquidationStatus.open;
}

enum AllocationMethod {
  manual(0, 'Elección del agricultor'),
  firstCome(1, 'Por orden de llegada'),
  unknown(-1, 'Sin definir');

  const AllocationMethod(this.wireValue, this.label);

  final int wireValue;
  final String label;

  static AllocationMethod fromWire(Object? value) => switch (value) {
    0 => AllocationMethod.manual,
    1 => AllocationMethod.firstCome,
    _ => AllocationMethod.unknown,
  };
}

class Liquidation {
  const Liquidation({
    required this.id,
    required this.supplierId,
    required this.productName,
    required this.quantity,
    required this.unitOfMeasure,
    required this.totalPrice,
    required this.unitPrice,
    required this.deliveryTime,
    required this.locationId,
    required this.visibility,
    required this.allocationMethod,
    required this.status,
    required this.closedAt,
    required this.expiresAt,
    required this.assignedBuyerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Liquidation.fromJson(Map<String, dynamic> json) => Liquidation(
    id: json['id'] as String? ?? '',
    supplierId: json['supplier_id'] as String? ?? '',
    productName: json['product_name'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
    unitOfMeasure: json['unit_of_measure'] as String? ?? '',
    totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
    unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
    deliveryTime: json['delivery_time'] as String?,
    locationId: json['location_id'] as String?,
    visibility: LiquidationVisibility.fromWire(json['visibility']),
    allocationMethod: AllocationMethod.fromWire(json['allocation_method']),
    status: LiquidationStatus.fromWire(json['status']),
    closedAt: json['closed_at'] as String?,
    expiresAt: json['expires_at'] as String?,
    assignedBuyerId: json['assigned_buyer_id'] as String?,
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
  );

  final String id;
  final String supplierId;
  final String productName;
  final double quantity;
  final String unitOfMeasure;
  final double totalPrice;
  final double unitPrice;
  final String? deliveryTime;
  final String? locationId;
  final LiquidationVisibility visibility;
  final AllocationMethod allocationMethod;
  final LiquidationStatus status;
  final String? closedAt;
  final String? expiresAt;
  final String? assignedBuyerId;
  final String? createdAt;
  final String? updatedAt;

  bool get isOpen => status.isOpen;
}
