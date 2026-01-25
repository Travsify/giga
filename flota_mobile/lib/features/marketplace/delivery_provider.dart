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
      final estimation = await _repository.estimateFare(request);
      state = state.copyWith(estimation: estimation, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
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
