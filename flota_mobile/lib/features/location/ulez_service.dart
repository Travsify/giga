import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Real London ULEZ Boundary (Simplified polygon - North/South Circular approximation)
/// For production, use the official TFL GeoJSON boundary.
class ULEZService {
  // Expanded ULEZ boundary (Approximate London-wide as of Aug 2023)
  static const List<LatLng> _ulezPolygon = [
    LatLng(51.6914, -0.4724), // Harefield (NW)
    LatLng(51.6668, -0.1643), // Barnet (N)
    LatLng(51.5973, 0.2289),  // Romford (NE)
    LatLng(51.4882, 0.3201),  // Rainham (E)
    LatLng(51.3411, 0.1504),  // Orpington (SE)
    LatLng(51.2980, -0.1197), // Coulsdon (S)
    LatLng(51.3653, -0.3664), // Chessington (SW)
    LatLng(51.4820, -0.5011), // Heathrow (W)
    LatLng(51.6914, -0.4724), // Back to Harefield
  ];

  /// Check if a coordinate is inside the ULEZ boundary.
  /// NOTE: For production, this should integrate with the TFL Unified API 
  /// (https://api.tfl.gov.uk/Vehicle/UlezCompliance) using the vehicle VRN.
  static Future<bool> isAddressInULEZ(LatLng location) async {
    // Simulate API latency
    await Future.delayed(const Duration(milliseconds: 300));
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
