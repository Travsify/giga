import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Real London ULEZ Boundary (Simplified polygon - North/South Circular approximation)
/// For production, use the official TFL GeoJSON boundary.
class ULEZService {
  // Approximate ULEZ boundary (London-wide as of 2023 expansion)
  // This is a simplified polygon; real zones use ~2000+ points
  static const List<LatLng> _ulezPolygon = [
    LatLng(51.6135, -0.2700), // Brent Cross
    LatLng(51.6015, -0.1500), // Finchley
    LatLng(51.5935, -0.0700), // Bounds Green
    LatLng(51.5850, 0.0000),  // Edmonton
    LatLng(51.5500, 0.0500),  // Walthamstow
    LatLng(51.5100, 0.0700),  // Stratford
    LatLng(51.4700, 0.0600),  // Beckton
    LatLng(51.4500, 0.0200),  // Woolwich
    LatLng(51.4300, -0.0500), // Greenwich
    LatLng(51.4100, -0.1000), // Lewisham
    LatLng(51.3900, -0.1500), // Norwood
    LatLng(51.3800, -0.2000), // Streatham
    LatLng(51.4000, -0.2700), // Wimbledon
    LatLng(51.4500, -0.3100), // Richmond
    LatLng(51.5000, -0.3400), // Chiswick
    LatLng(51.5500, -0.3200), // Ealing
    LatLng(51.5800, -0.2900), // Wembley
    LatLng(51.6135, -0.2700), // Back to Brent Cross (close polygon)
  ];

  /// Check if a coordinate is inside the ULEZ boundary using Ray Casting algorithm
  static Future<bool> isAddressInULEZ(LatLng location) async {
    // Simulate small network delay for consistent UX
    await Future.delayed(const Duration(milliseconds: 100));
    return _isPointInPolygon(location, _ulezPolygon);
  }

  /// Ray Casting Algorithm for Point-in-Polygon detection
  static bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersections = 0;
    int n = polygon.length;

    for (int i = 0; i < n; i++) {
      LatLng p1 = polygon[i];
      LatLng p2 = polygon[(i + 1) % n];

      if (point.latitude > _min(p1.latitude, p2.latitude) &&
          point.latitude <= _max(p1.latitude, p2.latitude) &&
          point.longitude <= _max(p1.longitude, p2.longitude)) {
        double xIntersect = (point.latitude - p1.latitude) *
                (p2.longitude - p1.longitude) /
                (p2.latitude - p1.latitude) +
            p1.longitude;

        if (p1.longitude == p2.longitude || point.longitude <= xIntersect) {
          intersections++;
        }
      }
    }

    return intersections % 2 != 0;
  }

  static double _min(double a, double b) => a < b ? a : b;
  static double _max(double a, double b) => a > b ? a : b;

  /// Calculate ULEZ charge based on vehicle type
  static double calculateCharge({required bool isElectric, bool isMotorcycle = false}) {
    if (isElectric) return 0.0;
    if (isMotorcycle) return 0.0; // Most motorcycles are exempt
    return 12.50; // Standard daily ULEZ charge
  }

  /// Get the ULEZ polygon for display on map
  static List<LatLng> getULEZPolygon() => _ulezPolygon;
}
