import 'package:flutter_application_1/features/buyer/supply_request_models.dart';

enum OfferStatus {
  active(0, 'Activa'),
  matched(1, 'Aceptada'),
  rejected(2, 'Rechazada'),
  withdrawn(3, 'Retirada'),
  unknown(-1, 'Desconocida');

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
}

class MatchOffer {
  const MatchOffer({
    required this.id,
    required this.supplierId,
    required this.supplyRequest,
    required this.totalAmount,
    required this.amountUnit,
    required this.pricePerUnit,
    required this.comments,
    required this.proposedDeliveryDay,
    required this.deliveryAvailable,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MatchOffer.fromJson(Map<String, dynamic> json) => MatchOffer(
    id: json['id'] as String? ?? '',
    supplierId: json['supplier_id'] as String? ?? '',
    supplyRequest: json['supply_request_id'] as String? ?? '',
    totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
    amountUnit: MeasureUnit.fromWire(
      json['measurement'] ?? json['amount_unit'],
    ),
    pricePerUnit: (json['price_per_unit'] as num?)?.toDouble(),
    comments: json['comments'] as String? ?? '',
    proposedDeliveryDay: json['delivery_day'] as String?,
    deliveryAvailable: json['delivery_available'] as bool? ?? false,
    status: OfferStatus.fromWire(json['status']),
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
  );

  final String id;
  final String supplierId;
  final String supplyRequest;
  final double totalAmount;
  final MeasureUnit amountUnit;
  final double? pricePerUnit;
  final String comments;
  final String? proposedDeliveryDay;
  final bool deliveryAvailable;
  final OfferStatus status;
  final String? createdAt;
  final String? updatedAt;
}

class ScoreContribution {
  const ScoreContribution({
    required this.factor,
    required this.weight,
    required this.score,
    required this.weightedScore,
  });

  factory ScoreContribution.fromJson(Map<String, dynamic> json) =>
      ScoreContribution(
        factor: json['factor'] as String? ?? '',
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
        score: (json['score'] as num?)?.toDouble() ?? 0,
        weightedScore: (json['weighted_score'] as num?)?.toDouble() ?? 0,
      );

  final String factor;
  final double weight;
  final double score;
  final double weightedScore;

  String get label => switch (factor) {
    'distance' => 'Distancia',
    'availability' => 'Disponibilidad',
    'price' => 'Precio',
    'delivery_time' => 'Tiempo de entrega',
    'reputation' => 'Reputación',
    _ => factor,
  };
}

class PrioritizedOffer {
  const PrioritizedOffer({
    required this.offer,
    required this.score,
    required this.availableQuantity,
    required this.distanceKm,
    required this.contributions,
  });

  factory PrioritizedOffer.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> offer = json['offer'] is Map
        ? Map<String, dynamic>.from(json['offer'] as Map)
        : <String, dynamic>{};
    return PrioritizedOffer(
      offer: MatchOffer.fromJson(offer),
      score: (json['score'] as num?)?.toDouble() ?? 0,
      availableQuantity: (json['available_quantity'] as num?)?.toDouble() ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      contributions: (json['contributions'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ScoreContribution.fromJson)
          .toList(),
    );
  }

  final MatchOffer offer;
  final double score;
  final double availableQuantity;
  final double? distanceKm;
  final List<ScoreContribution> contributions;
}

class MatchResult {
  const MatchResult({required this.matchId, required this.transactionId});

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> match = json['match'] is Map
        ? Map<String, dynamic>.from(json['match'] as Map)
        : <String, dynamic>{};
    final Map<String, dynamic> transaction = json['transaction'] is Map
        ? Map<String, dynamic>.from(json['transaction'] as Map)
        : <String, dynamic>{};
    return MatchResult(
      matchId: match['id'] as String? ?? '',
      transactionId: transaction['id'] as String? ?? '',
    );
  }

  final String matchId;
  final String transactionId;
}
