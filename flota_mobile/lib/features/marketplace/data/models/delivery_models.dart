class DeliveryStopModel {
  final String address;
  final double lat;
  final double lng;
  final String type; // pickup, dropoff
  final String? instructions;

  DeliveryStopModel({
    required this.address,
    required this.lat,
    required this.lng,
    required this.type,
    this.instructions,
  });

  Map<String, dynamic> toJson() => {
    'address': address,
    'lat': lat,
    'lng': lng,
    'type': type,
    'instructions': instructions,
  };
}

class DeliveryEstimationRequest {
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String vehicleType;
  final String serviceTier;
  final String? parcelCategory;
  final String? parcelSize;
  final List<DeliveryStopModel>? stops;

  DeliveryEstimationRequest({
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.vehicleType,
    required this.serviceTier,
    this.parcelCategory,
    this.parcelSize,
    this.stops,
  });

  Map<String, dynamic> toJson() => {
    'pickup_lat': pickupLat,
    'pickup_lng': pickupLng,
    'dropoff_lat': dropoffLat,
    'dropoff_lng': dropoffLng,
    'vehicle_type': vehicleType,
    'service_tier': serviceTier,
    'parcel_category': parcelCategory,
    'parcel_size': parcelSize,
    'stops': stops?.map((s) => s.toJson()).toList(),
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
  final String? parcelCategory;
  final String? parcelSize;
  final String? parcelPhotoUrl;
  final String? description;
  final DateTime? scheduledTime;
  final List<DeliveryStopModel>? stops;

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
    this.parcelCategory,
    this.parcelSize,
    this.parcelPhotoUrl,
    this.description,
    this.scheduledTime,
    this.stops,
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
    'parcel_category': parcelCategory ?? 'General',
    'parcel_size': parcelSize ?? 'Medium',
    'parcel_photo_url': parcelPhotoUrl,
    'description': description,
    'scheduled_time': scheduledTime?.toIso8601String(),
    'stops': stops?.map((s) => s.toJson()).toList(),
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
