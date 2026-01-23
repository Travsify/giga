import 'package:google_maps_flutter/google_maps_flutter.dart';

class ULEZService {
  // Mock Central London Bounding Box
  static const double _minLat = 51.490;
  static const double _maxLat = 51.520;
  static const double _minLng = -0.150;
  static const double _maxLng = -0.050;

  static Future<bool> isAddressInULEZ(LatLng location) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (location.latitude >= _minLat && location.latitude <= _maxLat &&
        location.longitude >= _minLng && location.longitude <= _maxLng) {
      return true;
    }
    return false;
  }

  static double calculateCharge(bool isElectric) {
    if (isElectric) return 0.0;
    return 12.50; // Standard ULEZ charge
  }
}
