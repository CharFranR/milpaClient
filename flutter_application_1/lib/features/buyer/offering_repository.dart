import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/features/buyer/offering_models.dart';

class OfferingRepository {
  OfferingRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<OfferingDetail> fetchDetail(String offeringId) async {
    final dynamic json = await _api.get('/offerings/$offeringId');
    return OfferingDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<SellerProfile> fetchSeller(String userId) async {
    final dynamic json = await _api.get('/users/$userId');
    return SellerProfile.fromJson(json as Map<String, dynamic>);
  }

  Future<RatingSummary> fetchRating(String userId) async {
    final dynamic json = await _api.get(
      '/reviews/average',
      query: <String, String>{'target_type': 'user', 'target_id': userId},
    );
    return RatingSummary.fromJson(json as Map<String, dynamic>);
  }
}
