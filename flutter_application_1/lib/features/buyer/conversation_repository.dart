import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/api_exception.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/conversation_models.dart';

class ConversationRepository {
  ConversationRepository({
    required ApiClient apiClient,
    required this._tokenStore,
  }) : _api = apiClient;

  final ApiClient _api;
  final TokenStore _tokenStore;

  Future<Conversation> start({
    required String farmerId,
    required String offeringId,
  }) async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.post(
      '/conversations',
      body: <String, dynamic>{'farmer_id': farmerId, 'offering_id': offeringId},
      token: token,
    );
    return Conversation.fromJson(json as Map<String, dynamic>);
  }

  Future<List<Conversation>> fetchAll() async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.get('/conversations', token: token);
    return _listItems(json)
        .map((Map<String, dynamic> item) => Conversation.fromJson(item))
        .toList();
  }

  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    final String token = await _readTokenOrThrow();
    final dynamic json = await _api.get(
      '/conversations/$conversationId/messages',
      token: token,
    );
    return _listItems(json)
        .map((Map<String, dynamic> item) => ChatMessage.fromJson(item))
        .toList();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final String token = await _readTokenOrThrow();
    await _api.post(
      '/messages',
      body: <String, dynamic>{
        'conversation_id': conversationId,
        'content': content,
      },
      token: token,
    );
  }

  Future<String> _readTokenOrThrow() async {
    final String? token = await _tokenStore.readToken();
    if (token == null) {
      throw const ApiException(401, 'Sesión no disponible');
    }
    return token;
  }

  List<Map<String, dynamic>> _listItems(dynamic json) => json is List
      ? json.whereType<Map<String, dynamic>>().toList()
      : <Map<String, dynamic>>[];
}
