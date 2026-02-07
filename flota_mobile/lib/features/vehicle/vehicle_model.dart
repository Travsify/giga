class Vehicle {
  final int id;
  final int riderId;
  final String vehicleType;
  final String vehiclePlateNumber;
  final String? make;
  final String? model;
  final String? color;
  final String? year;
  final bool isVerified;
  final String verificationStatus;
  final Map<String, dynamic>? verificationErrors;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.riderId,
    required this.vehicleType,
    required this.vehiclePlateNumber,
    this.make,
    this.model,
    this.color,
    this.year,
    required this.isVerified,
    required this.verificationStatus,
    this.verificationErrors,
    required this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      riderId: json['rider_id'],
      vehicleType: json['vehicle_type'],
      vehiclePlateNumber: json['vehicle_plate_number'],
      make: json['make'],
      model: json['model'],
      color: json['color'],
      year: json['year'],
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      verificationStatus: json['verification_status'] ?? 'pending',
      verificationErrors: json['verification_errors'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rider_id': riderId,
      'vehicle_type': vehicleType,
      'vehicle_plate_number': vehiclePlateNumber,
      'make': make,
      'model': model,
      'color': color,
      'year': year,
      'is_verified': isVerified,
      'verification_status': verificationStatus,
      'verification_errors': verificationErrors,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
