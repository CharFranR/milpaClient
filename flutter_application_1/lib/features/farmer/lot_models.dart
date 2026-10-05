import 'package:flutter_application_1/features/buyer/liquidation_models.dart';

class LotDraft {
  const LotDraft({
    required this.productName,
    required this.quantity,
    required this.unitOfMeasure,
    required this.unitPrice,
    required this.visibility,
    required this.allocationMethod,
    this.expiresAt,
  });

  final String productName;
  final double quantity;
  final String unitOfMeasure;
  final double unitPrice;
  final LiquidationVisibility visibility;
  final AllocationMethod allocationMethod;
  final DateTime? expiresAt;

  double get totalPrice => quantity * unitPrice;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'product_name': productName.trim(),
    'quantity': quantity,
    'unit_of_measure': unitOfMeasure,
    'total_price': totalPrice,
    'unit_price': unitPrice,
    'visibility': visibility.wire,
    'allocation_method': allocationMethod.wireValue,
    if (expiresAt != null) 'expires_at': expiresAt!.toUtc().toIso8601String(),
  };
}

class InterestedBuyer {
  const InterestedBuyer({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.createdAt,
  });

  factory InterestedBuyer.fromJson(Map<String, dynamic> json) =>
      InterestedBuyer(
        id: json['id'] as String? ?? '',
        buyerId: json['buyer_id'] as String? ?? '',
        buyerName: json['buyer_name'] as String? ?? '',
        createdAt: json['created_at'] as String?,
      );

  final String id;
  final String buyerId;
  final String buyerName;
  final String? createdAt;
}
