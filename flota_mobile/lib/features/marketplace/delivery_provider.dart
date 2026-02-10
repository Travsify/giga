import 'dart:math' as Math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/features/marketplace/data/delivery_repository.dart';
import 'package:flota_mobile/features/marketplace/data/models/delivery_models.dart';

class DeliveryState {
  final bool isLoading;
  final DeliveryEstimationResponse? estimation;
  final String? error;
  final Map<String, dynamic>? lastCreatedDelivery;
  final List<Map<String, dynamic>> userDeliveries;

  DeliveryState({
    this.isLoading = false,
    this.estimation,
    this.error,
    this.lastCreatedDelivery,
    this.userDeliveries = const [],
  });

  DeliveryState copyWith({
    bool? isLoading,
    DeliveryEstimationResponse? estimation,
    String? error,
    Map<String, dynamic>? lastCreatedDelivery,
    List<Map<String, dynamic>>? userDeliveries,
  }) {
    return DeliveryState(
      isLoading: isLoading ?? this.isLoading,
      estimation: estimation ?? this.estimation,
      error: error ?? this.error,
      lastCreatedDelivery: lastCreatedDelivery ?? this.lastCreatedDelivery,
      userDeliveries: userDeliveries ?? this.userDeliveries,
    );
  }
}

class DeliveryNotifier extends StateNotifier<DeliveryState> {
  final DeliveryRepository _repository;

  DeliveryNotifier(this._repository) : super(DeliveryState());

  Future<void> estimateFare(DeliveryEstimationRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Backend Estimation (Primary)
      final estimation = await _repository.estimateFare(request);
      state = state.copyWith(estimation: estimation, isLoading: false);
    } catch (e) {
      // 2. Client-side Fallback (Based on distance)
      final distance = _calculateDistance(
        request.pickupLat, request.pickupLng,
        request.dropoffLat, request.dropoffLng
      );
      
      // Calculate a rough fare (₦500 base + ₦150/km) - Nigeria specific logic
      final basePrice = request.vehicleType == 'Bike' ? 500.0 : 1500.0;
      final perKm = request.vehicleType == 'Bike' ? 150.0 : 300.0;
      final estimatedTotal = basePrice + (distance * perKm);
      
      final fallbackEstimation = DeliveryEstimationResponse(
        distanceKm: distance,
        estimatedTotal: estimatedTotal,
        discount: 0,
        finalFare: estimatedTotal,
        currency: 'NGN',
        isGigaPlus: false,
      );
      
      state = state.copyWith(estimation: fallbackEstimation, isLoading: false);
      debugPrint('Fallback estimation used: $distance km, ₦$estimatedTotal');
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var a = 0.5 - Math.cos((lat2 - lat1) * p) / 2 +
        Math.cos(lat1 * p) * Math.cos(lat2 * p) *
        (1 - Math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * Math.asin(Math.sqrt(a)); // 2 * R; R = 6371 km
  }

  Future<bool> createDelivery(DeliveryRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final delivery = await _repository.createDelivery(request);
      state = state.copyWith(lastCreatedDelivery: delivery, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<void> fetchUserDeliveries({List<String>? statuses}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final deliveries = await _repository.getDeliveries(statuses: statuses);
      state = state.copyWith(userDeliveries: deliveries, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final deliveryProvider = StateNotifierProvider<DeliveryNotifier, DeliveryState>((ref) {
  final repository = ref.watch(deliveryRepositoryProvider);
  return DeliveryNotifier(repository);
});
