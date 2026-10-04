import 'package:flutter_application_1/core/api_client.dart';
import 'package:flutter_application_1/core/token_store.dart';
import 'package:flutter_application_1/features/buyer/supply_request_models.dart';
import 'package:flutter_application_1/features/buyer/supply_request_repository.dart';

class FakeSupplyRequestRepository extends SupplyRequestRepository {
  FakeSupplyRequestRepository({List<SupplyRequest>? requests})
    : requests = List<SupplyRequest>.of(requests ?? <SupplyRequest>[]),
      super(apiClient: ApiClient(), tokenStore: TokenStore());

  final List<SupplyRequest> requests;
  Object? fetchError;
  Object? createError;
  Object? updateError;
  Object? cancelError;
  int fetchAllCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int cancelCalls = 0;
  SupplyRequestDraft? lastDraft;
  String? lastUpdatedId;
  String? lastUpdateId;
  String? lastCancelledId;
  String? lastCancelId;
  SupplyRequest? created;

  @override
  Future<List<SupplyRequest>> fetchAll() async {
    fetchAllCalls++;
    if (fetchError != null) throw fetchError!;
    return List<SupplyRequest>.of(requests);
  }

  @override
  Future<SupplyRequest> create(SupplyRequestDraft draft) async {
    createCalls++;
    lastDraft = draft;
    if (createError != null) throw createError!;
    return created ?? buildSupplyRequest();
  }

  @override
  Future<void> update(String id, SupplyRequestDraft draft) async {
    updateCalls++;
    lastUpdatedId = id;
    lastUpdateId = id;
    lastDraft = draft;
    if (updateError != null) throw updateError!;
  }

  @override
  Future<void> cancel(String id) async {
    cancelCalls++;
    lastCancelledId = id;
    lastCancelId = id;
    if (cancelError != null) throw cancelError!;
    requests.removeWhere((SupplyRequest request) => request.id == id);
  }
}

SupplyRequest buildSupplyRequest({
  String id = 'request-1',
  String productName = 'Café pergamino',
  double totalAmount = 800,
  double actualAmount = 300,
  MeasureUnit amountUnit = MeasureUnit.kilogram,
  double numberOfUnits = 100,
  double amountPerUnit = 8,
  MeasureUnit unitOfMeasure = MeasureUnit.kilogram,
  String department = 'Managua',
  String municipality = 'Managua',
  String addressLine = 'Bodega 12',
  String? requestDeadline = '2026-11-01T00:00:00Z',
  String? deliveryDeadline = '2026-12-01T00:00:00Z',
  bool multipleProviders = true,
  double minAmountPerProvider = 100,
  SupplyRequestStatus status = SupplyRequestStatus.open,
}) => SupplyRequest(
  id: id,
  buyerId: 'buyer-1',
  productName: productName,
  description: 'Compra de temporada',
  totalAmount: totalAmount,
  actualAmount: actualAmount,
  amountUnit: amountUnit,
  numberOfUnits: numberOfUnits,
  amountPerUnit: amountPerUnit,
  unitOfMeasure: unitOfMeasure,
  department: department,
  municipality: municipality,
  addressLine: addressLine,
  latitude: 12.136,
  longitude: -86.251,
  requestDeadline: requestDeadline,
  deliveryDeadline: deliveryDeadline,
  multipleProviders: multipleProviders,
  minAmountPerProvider: minAmountPerProvider,
  status: status,
  createdAt: '2026-10-04T07:42:02Z',
  updatedAt: '2026-10-04T07:42:02Z',
);
