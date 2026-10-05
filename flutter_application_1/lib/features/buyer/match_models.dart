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

enum MatchStatus {
  active(0, 'Activo'),
  cancelled(1, 'Cancelado'),
  unknown(-1, 'Desconocido');

  const MatchStatus(this.wireValue, this.label);

  final int wireValue;
  final String label;

  static MatchStatus fromWire(Object? value) => switch (value) {
    0 => MatchStatus.active,
    1 => MatchStatus.cancelled,
    _ => MatchStatus.unknown,
  };
}

class Match {
  const Match({
    required this.id,
    required this.supplyOffer,
    required this.supplyRequest,
    required this.status,
    required this.matchedAmount,
    required this.amountUnit,
    this.createdAt,
    this.updatedAt,
  });

  factory Match.fromJson(Map<String, dynamic> json) => Match(
    id: json['id'] as String? ?? '',
    supplyOffer: json['supply_offer'] as String? ?? '',
    supplyRequest: json['supply_request'] as String? ?? '',
    status: MatchStatus.fromWire(json['status']),
    matchedAmount: (json['matched_amount'] as num?)?.toDouble() ?? 0,
    amountUnit: MeasureUnit.fromWire(json['amount_unit']),
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
  );

  final String id;
  final String supplyOffer;
  final String supplyRequest;
  final MatchStatus status;
  final double matchedAmount;
  final MeasureUnit amountUnit;
  final String? createdAt;
  final String? updatedAt;
}

enum TransactionStatus {
  matched(0, 'Acordada'),
  inProgress(1, 'En proceso'),
  completed(2, 'Completada'),
  cancelled(3, 'Cancelada'),
  unknown(-1, 'Desconocida');

  const TransactionStatus(this.wireValue, this.label);

  final int wireValue;
  final String label;

  static TransactionStatus fromWire(Object? value) => switch (value) {
    0 => TransactionStatus.matched,
    1 => TransactionStatus.inProgress,
    2 => TransactionStatus.completed,
    3 => TransactionStatus.cancelled,
    _ => TransactionStatus.unknown,
  };

  bool get isTerminal =>
      this == TransactionStatus.completed || this == TransactionStatus.cancelled;
}

class Transaction {
  const Transaction({
    required this.id,
    required this.matchId,
    required this.status,
    this.buyerStartConfirmedAt,
    this.supplierStartConfirmedAt,
    this.buyerDeliveryConfirmedAt,
    this.supplierDeliveryConfirmedAt,
    this.cancelledBy,
    this.cancelReason = '',
    this.createdAt,
    this.updatedAt,
    this.historyCount = 0,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String? ?? '',
    matchId: json['match_id'] as String? ?? '',
    status: TransactionStatus.fromWire(json['status']),
    buyerStartConfirmedAt: json['buyer_start_confirmed_at'] as String?,
    supplierStartConfirmedAt: json['supplier_start_confirmed_at'] as String?,
    buyerDeliveryConfirmedAt: json['buyer_delivery_confirmed_at'] as String?,
    supplierDeliveryConfirmedAt:
        json['supplier_delivery_confirmed_at'] as String?,
    cancelledBy: json['cancelled_by'] as String?,
    cancelReason: json['cancel_reason'] as String? ?? '',
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
    historyCount: (json['history'] as List<dynamic>?)?.length ?? 0,
  );

  final String id;
  final String matchId;
  final TransactionStatus status;
  final String? buyerStartConfirmedAt;
  final String? supplierStartConfirmedAt;
  final String? buyerDeliveryConfirmedAt;
  final String? supplierDeliveryConfirmedAt;
  final String? cancelledBy;
  final String cancelReason;
  final String? createdAt;
  final String? updatedAt;
  final int historyCount;
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
