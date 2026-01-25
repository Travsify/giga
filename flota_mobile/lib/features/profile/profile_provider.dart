import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/features/profile/data/profile_repository.dart';

class ProfileState {
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? loyalty;
  final Map<String, dynamic>? subscription;
  final bool isLoading;
  final String? error;

  ProfileState({
    this.user,
    this.loyalty,
    this.subscription,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    Map<String, dynamic>? user,
    Map<String, dynamic>? loyalty,
    Map<String, dynamic>? subscription,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      user: user ?? this.user,
      loyalty: loyalty ?? this.loyalty,
      subscription: subscription ?? this.subscription,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;

  ProfileNotifier(this._repository) : super(ProfileState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repository.getProfile();
      final loyalty = await _repository.getLoyaltyInfo();
      final subscription = await _repository.getSubscriptionStatus();
      state = state.copyWith(
        user: user, 
        loyalty: loyalty, 
        subscription: subscription,
        isLoading: false
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> updateProfile({
    String? name,
    String? ukPhone,
    String? homeAddress,
    String? workAddress,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (ukPhone != null) data['uk_phone'] = ukPhone;
      if (homeAddress != null) data['home_address'] = homeAddress;
      if (workAddress != null) data['work_address'] = workAddress;

      final updatedUser = await _repository.updateProfile(data);
      state = state.copyWith(user: updatedUser, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> submitReferral(String code) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.submitReferralCode(code);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> subscribe() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.subscribe();
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
  Future<void> cancelSubscription() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.cancelSubscription();
      await refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository);
});
