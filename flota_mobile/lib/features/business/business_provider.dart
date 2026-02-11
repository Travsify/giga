import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/features/business/data/business_repository.dart';

class BusinessState {
  final bool isLoading;
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? fleetStats;
  final List<dynamic>? fleetRiders;
  final List<dynamic>? recentActivity;
  final List<dynamic>? apiKeys;
  final String? error;

  BusinessState({
    this.isLoading = false,
    this.profile,
    this.fleetStats,
    this.fleetRiders,
    this.recentActivity,
    this.apiKeys,
    this.error,
  });

  BusinessState copyWith({
    bool? isLoading,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? fleetStats,
    List<dynamic>? fleetRiders,
    List<dynamic>? recentActivity,
    List<dynamic>? apiKeys,
    String? error,
  }) {
    return BusinessState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      fleetStats: fleetStats ?? this.fleetStats,
      fleetRiders: fleetRiders ?? this.fleetRiders,
      recentActivity: recentActivity ?? this.recentActivity,
      apiKeys: apiKeys ?? this.apiKeys,
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
      await _repository.getTeam();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchFleetDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final stats = await _repository.getFleetStats();
      final riders = await _repository.getFleetRiders();
      final activity = await _repository.getRecentActivity();
      
      state = state.copyWith(
        isLoading: false,
        fleetStats: stats,
        fleetRiders: riders,
        recentActivity: activity,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> onboardRider(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.onboardRider(data);
      await fetchFleetDashboard(); // Refresh
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> fetchApiKeys() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final keys = await _repository.getApiKeys();
      state = state.copyWith(isLoading: false, apiKeys: keys);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Map<String, dynamic>?> generateApiKey(String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.generateApiKey(name);
      await fetchApiKeys(); // Refresh list
      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> revokeApiKey(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.revokeApiKey(id);
      await fetchApiKeys(); // Refresh list
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final businessProvider = StateNotifierProvider<BusinessNotifier, BusinessState>((ref) {
  final repository = ref.watch(businessRepositoryProvider);
  return BusinessNotifier(repository);
});
