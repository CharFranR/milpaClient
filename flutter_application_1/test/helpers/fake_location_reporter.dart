import 'package:flutter_application_1/core/location_reporter.dart';

class FakeLocationReporter implements LocationReporter {
  FakeLocationReporter({this.result});

  final Coordinates? result;
  int calls = 0;
  int grantedCalls = 0;

  @override
  Future<Coordinates?> capture() async {
    calls++;
    return result;
  }

  @override
  Future<Coordinates?> captureGranted() async {
    grantedCalls++;
    return result;
  }
}
