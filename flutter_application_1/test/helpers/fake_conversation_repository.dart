import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/conversation_models.dart';
import 'package:flutter_application_1/features/buyer/conversation_repository.dart';

class FakeConversationRepository extends ConversationRepository {
  FakeConversationRepository()
    : super(apiClient: ApiClient(), tokenStore: TokenStore());

  Object? startError;
  int startCalls = 0;
  String? lastFarmerId;
  String? lastOfferingId;

  List<Conversation> conversations = <Conversation>[];
  Object? fetchAllError;
  int fetchAllCalls = 0;

  final Map<String, List<ChatMessage>> messagesByConversation =
      <String, List<ChatMessage>>{};
  Object? fetchMessagesError;
  Set<String> messageErrorConversationIds = <String>{};
  int fetchMessagesCalls = 0;
  String? lastFetchedConversationId;

  Object? sendMessageError;
  int sendMessageCalls = 0;
  String? lastSendConversationId;
  String? lastSendContent;

  @override
  Future<Conversation> start({
    required String farmerId,
    required String offeringId,
  }) async {
    startCalls++;
    lastFarmerId = farmerId;
    lastOfferingId = offeringId;
    final Object? error = startError;
    if (error != null) throw error;
    return Conversation(
      id: 'conversation-1',
      farmerId: farmerId,
      buyerId: 'buyer-1',
      offeringId: offeringId,
      visibility: true,
    );
  }

  @override
  Future<List<Conversation>> fetchAll() async {
    fetchAllCalls++;
    final Object? error = fetchAllError;
    if (error != null) throw error;
    return conversations;
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    fetchMessagesCalls++;
    lastFetchedConversationId = conversationId;
    if (messageErrorConversationIds.contains(conversationId)) {
      throw Exception('sin mensajes');
    }
    final Object? error = fetchMessagesError;
    if (error != null) throw error;
    return messagesByConversation[conversationId] ?? <ChatMessage>[];
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    sendMessageCalls++;
    lastSendConversationId = conversationId;
    lastSendContent = content;
    final Object? error = sendMessageError;
    if (error != null) throw error;
  }
}
