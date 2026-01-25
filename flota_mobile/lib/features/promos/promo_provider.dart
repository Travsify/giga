import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/features/promos/data/promo_repository.dart';

class PromoState {
  final bool isLoading;
  final List<Map<String, dynamic>> activePromos;
  final String? error;
  final Map<String, dynamic>? validationResult;

  PromoState({
    this.isLoading = false,
    this.activePromos = const [],
    this.error,
    this.validationResult,
  });

  PromoState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? activePromos,
    String? error,
    Map<String, dynamic>? validationResult,
  }) {
    return PromoState(
      isLoading: isLoading ?? this.isLoading,
      activePromos: activePromos ?? this.activePromos,
      error: error ?? this.error,
      validationResult: validationResult ?? this.validationResult,
    );
  }
}

class PromoNotifier extends StateNotifier<PromoState> {
  final PromoRepository _repository;

  PromoNotifier(this._repository) : super(PromoState());

  Future<void> fetchPromos() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final promos = await _repository.getPromos();
      state = state.copyWith(isLoading: false, activePromos: promos);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> validateCode(String code, double amount) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.validateCode(code, amount);
      state = state.copyWith(isLoading: false, validationResult: result);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final promoProvider = StateNotifierProvider<PromoNotifier, PromoState>((ref) {
  final repository = ref.watch(promoRepositoryProvider);
  return PromoNotifier(repository);
});
