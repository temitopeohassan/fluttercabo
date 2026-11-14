import 'package:geolocator/geolocator.dart';

class LatLng {
  const LatLng(this.lat, this.lng);
  final double lat;
  final double lng;
}

class LocationException implements Exception {
  LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Where the phone is. Screens depend on this interface so tests can supply
/// a fixed position.
abstract class LocationService {
  /// The current position. Throws [LocationException] with a message for the
  /// user when location is off or not allowed.
  Future<LatLng> current();
}

class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  @override
  Future<LatLng> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw LocationException('Location is turned off. Turn it on in your phone settings.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw LocationException('Cabo is not allowed to use your location. Allow it in your phone settings.');
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      return LatLng(p.latitude, p.longitude);
    } on LocationException {
      rethrow;
    } catch (_) {
      throw LocationException('Could not find your location. Move to an open area and try again.');
    }
  }
}

/// Always reports the same position. Used in tests.
class FixedLocationService implements LocationService {
  const FixedLocationService([this.position = const LatLng(6.4281, 3.4219)]);
  final LatLng position;

  @override
  Future<LatLng> current() async => position;
}
