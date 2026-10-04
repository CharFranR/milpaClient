import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/features/buyer/offering_models.dart';
import 'package:flutter_application_1/features/buyer/offering_repository.dart';

const OfferingDetail defaultFakeOffering = OfferingDetail(
  id: 'offering-1',
  userId: 'farmer-1',
  type: 0,
  name: 'Tomate cherry',
  description: 'Cosecha de la semana',
  price: 25.5,
  imageUrl: '',
);

const SellerProfile defaultFakeSeller = SellerProfile(
  id: 'farmer-1',
  firstName: 'María',
  lastName: 'López',
  role: 1,
  department: 'Matagalpa',
  municipality: 'Sebaco',
);

const RatingSummary defaultFakeRating = RatingSummary(average: 4.5, count: 12);

class FakeOfferingRepository extends OfferingRepository {
  FakeOfferingRepository({
    this.detail = defaultFakeOffering,
    this.seller = defaultFakeSeller,
    this.rating = defaultFakeRating,
  }) : super(apiClient: ApiClient());

  OfferingDetail detail;
  SellerProfile seller;
  RatingSummary rating;
  Object? detailError;
  Object? sellerError;
  Object? ratingError;
  int detailCalls = 0;
  int sellerCalls = 0;
  int ratingCalls = 0;
  String? lastDetailId;
  String? lastSellerId;
  String? lastRatingId;

  @override
  Future<OfferingDetail> fetchDetail(String offeringId) async {
    detailCalls++;
    lastDetailId = offeringId;
    final Object? error = detailError;
    if (error != null) throw error;
    return detail;
  }

  @override
  Future<SellerProfile> fetchSeller(String userId) async {
    sellerCalls++;
    lastSellerId = userId;
    final Object? error = sellerError;
    if (error != null) throw error;
    return seller;
  }

  @override
  Future<RatingSummary> fetchRating(String userId) async {
    ratingCalls++;
    lastRatingId = userId;
    final Object? error = ratingError;
    if (error != null) throw error;
    return rating;
  }
}
