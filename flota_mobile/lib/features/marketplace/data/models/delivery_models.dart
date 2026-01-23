class DeliveryEstimationRequest {
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String vehicleType;
  final String serviceTier;

  DeliveryEstimationRequest({
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.vehicleType,
    required this.serviceTier,
  });

  Map<String, dynamic> toJson() => {
    'pickup_lat': pickupLat,
    'pickup_lng': pickupLng,
    'dropoff_lat': dropoffLat,
    'dropoff_lng': dropoffLng,
    'vehicle_type': vehicleType,
    'service_tier': serviceTier,
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
  final String serviceTier;
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
    required this.serviceTier,
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
    'service_tier': serviceTier,
    'fare': fare,
    'parcel_type': parcelType ?? 'Standard',
    'description': description,
  };
}

class DeliveryEstimationResponse {
  final double distanceKm;
  final double estimatedTotal;
  final double discount;
  final double finalFare;
  final String currency;
  final bool isGigaPlus;

  DeliveryEstimationResponse({
    required this.distanceKm,
    required this.estimatedTotal,
    required this.discount,
    required this.finalFare,
    required this.currency,
    required this.isGigaPlus,
  });

  factory DeliveryEstimationResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryEstimationResponse(
      distanceKm: (json['distance_km'] as num).toDouble(),
      estimatedTotal: (json['estimated_total'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      finalFare: (json['final_fare'] as num).toDouble(),
      currency: json['currency'] as String,
      isGigaPlus: json['is_giga_plus'] as bool,
    );
  }
}
