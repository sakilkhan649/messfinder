import 'package:geolocator/geolocator.dart';
import '../utils/app_logger.dart';

class LocationService {
  /// Check if location services are enabled and request permission if needed.
  /// Returns the current Position if successful, otherwise null.
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.w('Location services are disabled.', tag: 'LOCATION');
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.w('Location permissions are denied', tag: 'LOCATION');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.w(
            'Location permissions are permanently denied, we cannot request permissions.',
            tag: 'LOCATION');
        return null;
      }

      // When we reach here, permissions are granted and we can
      // continue accessing the position of the device.
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      AppLogger.e('Error getting location: $e', null, null, 'LOCATION');
      return null;
    }
  }

  /// Calculates the distance between two coordinates in kilometers.
  static double calculateDistanceInKm(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    final distanceInMeters = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
    return distanceInMeters / 1000; // Convert to kilometers
  }
}
