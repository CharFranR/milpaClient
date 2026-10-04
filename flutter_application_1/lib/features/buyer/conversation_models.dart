class Conversation {
  const Conversation({
    required this.id,
    required this.farmerId,
    required this.buyerId,
    required this.offeringId,
    this.matchId,
    required this.visibility,
    this.createdAt,
    this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String? ?? '',
    farmerId: json['farmer_id'] as String? ?? '',
    buyerId: json['buyer_id'] as String? ?? '',
    offeringId: json['offering_id'] as String? ?? '',
    matchId: json['match_id'] as String?,
    visibility: json['visibility'] as bool? ?? false,
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
  );

  final String id;
  final String farmerId;
  final String buyerId;
  final String offeringId;
  final String? matchId;
  final bool visibility;
  final String? createdAt;
  final String? updatedAt;
}
