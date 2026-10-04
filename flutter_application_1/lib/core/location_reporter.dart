import 'package:geolocator/geolocator.dart';

class Coordinates {
  const Coordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

abstract class LocationReporter {
  Future<Coordinates?> capture();

  Future<Coordinates?> captureGranted();
}

class DeviceLocationReporter implements LocationReporter {
  const DeviceLocationReporter();

  @override
  Future<Coordinates?> capture() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return null;
      }

      return await _position();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Coordinates?> captureGranted() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      final LocationPermission permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return null;
      }

      return await _position();
    } catch (_) {
      return null;
    }
  }

  Future<Coordinates> _position() async {
    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return Coordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
