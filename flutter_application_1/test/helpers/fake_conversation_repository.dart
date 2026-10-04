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
}
