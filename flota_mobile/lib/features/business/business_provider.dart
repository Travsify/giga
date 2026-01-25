import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/features/business/data/business_repository.dart';

class BusinessState {
  final bool isLoading;
  final Map<String, dynamic>? profile;
  final String? error;

  BusinessState({
    this.isLoading = false,
    this.profile,
    this.error,
  });

  BusinessState copyWith({
    bool? isLoading,
    Map<String, dynamic>? profile,
    String? error,
  }) {
    return BusinessState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      error: error ?? this.error,
    );
  }
}

class BusinessNotifier extends StateNotifier<BusinessState> {
  final BusinessRepository _repository;

  BusinessNotifier(this._repository) : super(BusinessState());

  Future<bool> enroll(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.enrollBusiness(data);
      state = state.copyWith(
        isLoading: false, 
        profile: response['business'],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repository.getBusinessProfile();
      state = state.copyWith(isLoading: false, profile: profile);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> bulkBook(List<Map<String, dynamic>> batch) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.bulkBook(batch);
      // Refresh profile to update balance
      await fetchProfile();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> fetchTeam() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // For now we just check if it works, storing in state could be complex 
      // if we need separate state for each feature, but for MVP this is fine.
      await _repository.getTeam();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final businessProvider = StateNotifierProvider<BusinessNotifier, BusinessState>((ref) {
  final repository = ref.watch(businessRepositoryProvider);
  return BusinessNotifier(repository);
});
