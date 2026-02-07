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
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Fetch profile first - this is critical
      final user = await _repository.getProfile();
      
      // Fetch loyalty and subscription separately to handle partial failures
      Map<String, dynamic>? loyalty;
      Map<String, dynamic>? subscription;
      
      try {
        loyalty = await _repository.getLoyaltyInfo();
      } catch (e) {
        // Loyalty failed but we can continue
        loyalty = {'loyalty_points': 0, 'referral_code': '', 'referral_count': 0};
      }
      
      try {
        subscription = await _repository.getSubscriptionStatus();
      } catch (e) {
        // Subscription failed but we can continue
        subscription = {'is_subscribed': false};
      }
      
      state = state.copyWith(
        user: user, 
        loyalty: loyalty, 
        subscription: subscription,
        isLoading: false,
        error: null,
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
    String? vehiclePlate,
    String? vehicleType,
    String? companyName,
    String? registrationNumber,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (ukPhone != null) data['uk_phone'] = ukPhone;
      if (homeAddress != null) data['home_address'] = homeAddress;
      if (workAddress != null) data['work_address'] = workAddress;
      if (vehiclePlate != null) data['vehicle_plate_number'] = vehiclePlate;
      if (vehicleType != null) data['vehicle_type'] = vehicleType;
      if (companyName != null) data['company_name'] = companyName;
      if (registrationNumber != null) data['registration_number'] = registrationNumber;

      final updatedUser = await _repository.updateProfile(data);
      state = state.copyWith(user: updatedUser, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<Map<String, dynamic>> verifyPlate(String plateNumber, String countryCode) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _repository.verifyPlate(plateNumber, countryCode);
      state = state.copyWith(isLoading: false);
      return res;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
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
