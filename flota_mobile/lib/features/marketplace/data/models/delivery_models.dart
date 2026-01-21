class DeliveryEstimationRequest {
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String vehicleType;

  DeliveryEstimationRequest({
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.vehicleType,
  });

  Map<String, dynamic> toJson() => {
    'pickup_lat': pickupLat,
    'pickup_lng': pickupLng,
    'dropoff_lat': dropoffLat,
    'dropoff_lng': dropoffLng,
    'vehicle_type': vehicleType,
  };
}

class DeliveryRequest {
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String vehicleType;
  final double fare;
  final String? parcelType;
  final String? description;

  DeliveryRequest({
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.vehicleType,
    required this.fare,
    this.parcelType,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'pickup_address': pickupAddress,
    'pickup_lat': pickupLat,
    'pickup_lng': pickupLng,
    'dropoff_address': dropoffAddress,
    'dropoff_lat': dropoffLat,
    'dropoff_lng': dropoffLng,
    'vehicle_type': vehicleType,
    'fare': fare,
    'parcel_type': parcelType ?? 'Standard',
    'description': description,
  };
}
