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

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    this.senderId,
    required this.content,
    required this.visibility,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: _stringOrEmpty(json['id']),
    conversationId: _stringOrEmpty(json['conversation_id']),
    senderId: _nullableString(json['sender_id']),
    content: _stringOrEmpty(json['content']),
    visibility: _boolOrDefault(json['visibility']),
    createdAt: _nullableString(json['created_at']),
  );

  final String id;
  final String conversationId;
  final String? senderId;
  final String content;
  final bool visibility;
  final String? createdAt;

  bool get isFromSponsor => senderId == null;
}

String _stringOrEmpty(Object? value) => value is String ? value : '';

String? _nullableString(Object? value) => value is String ? value : null;

bool _boolOrDefault(Object? value) => value is bool ? value : false;
