import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/features/marketplace/data/delivery_repository.dart';
import 'package:flota_mobile/features/marketplace/data/models/delivery_models.dart';

class DeliveryState {
  final bool isLoading;
  final DeliveryEstimationResponse? estimation;
  final String? error;
  final Map<String, dynamic>? lastCreatedDelivery;

  DeliveryState({
    this.isLoading = false,
    this.estimation,
    this.error,
    this.lastCreatedDelivery,
  });

  DeliveryState copyWith({
    bool? isLoading,
    DeliveryEstimationResponse? estimation,
    String? error,
    Map<String, dynamic>? lastCreatedDelivery,
  }) {
    return DeliveryState(
      isLoading: isLoading ?? this.isLoading,
      estimation: estimation ?? this.estimation,
      error: error ?? this.error,
      lastCreatedDelivery: lastCreatedDelivery ?? this.lastCreatedDelivery,
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
}

final deliveryProvider = StateNotifierProvider<DeliveryNotifier, DeliveryState>((ref) {
  final repository = ref.watch(deliveryRepositoryProvider);
  return DeliveryNotifier(repository);
});
