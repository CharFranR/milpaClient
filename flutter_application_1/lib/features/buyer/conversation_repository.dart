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
    final String? token = await _tokenStore.readToken();
    if (token == null) {
      throw const ApiException(401, 'Sesión no disponible');
    }
    final dynamic json = await _api.post(
      '/conversations',
      body: <String, dynamic>{'farmer_id': farmerId, 'offering_id': offeringId},
      token: token,
    );
    return Conversation.fromJson(json as Map<String, dynamic>);
  }
}
