import 'package:flutter_application_1/features/buyer/match_models.dart';
import 'package:flutter_application_1/features/buyer/supply_request_models.dart';

class Sale {
  const Sale({
    required this.offerId,
    required this.requestId,
    required this.productName,
    required this.amountUnit,
    required this.quantity,
    required this.pricePerUnit,
    required this.municipality,
    required this.buyerName,
    required this.transaction,
  });

  final String offerId;
  final String requestId;
  final String productName;
  final MeasureUnit amountUnit;
  final double quantity;
  final double pricePerUnit;
  final String municipality;
  final String buyerName;
  final Transaction transaction;
}
