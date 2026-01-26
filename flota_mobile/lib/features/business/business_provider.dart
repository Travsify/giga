import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/features/business/data/business_repository.dart';

class BusinessState {
  final bool isLoading;
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? stats;
  final List<dynamic> activity;
  final String? error;

  BusinessState({
    this.isLoading = false,
    this.profile,
    this.stats,
    this.activity = const [],
    this.error,
  });

  BusinessState copyWith({
    bool? isLoading,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? stats,
    List<dynamic>? activity,
    String? error,
  }) {
    return BusinessState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      stats: stats ?? this.stats,
      activity: activity ?? this.activity,
      error: error ?? this.error,
    );
  }
}

class BusinessNotifier extends StateNotifier<BusinessState> {
  final BusinessRepository _repository;

  BusinessNotifier(this._repository) : super(BusinessState()) {
    // Optionally fetch data on initialization if profile exists
  }

  Future<void> refreshDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repository.getBusinessProfile(),
        _repository.getStats(),
        _repository.getActivity(),
      ]);

      state = state.copyWith(
        isLoading: false,
        profile: results[0] as Map<String, dynamic>,
        stats: results[1] as Map<String, dynamic>,
        activity: results[2] as List<dynamic>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> enroll(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.enrollBusiness(data);
      state = state.copyWith(
        isLoading: false, 
        profile: response['business'],
      );
      await refreshDashboard();
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

  Future<void> fetchStats() async {
    try {
      final stats = await _repository.getStats();
      state = state.copyWith(stats: stats);
    } catch (e) {
      // Background fail
    }
  }

  Future<void> fetchActivity() async {
    try {
      final activity = await _repository.getActivity();
      state = state.copyWith(activity: activity);
    } catch (e) {
      // Background fail
    }
  }

  Future<bool> bulkBook(List<Map<String, dynamic>> batch) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.bulkBook(batch);
      await refreshDashboard();
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
}

final businessProvider = StateNotifierProvider<BusinessNotifier, BusinessState>((ref) {
  final repository = ref.watch(businessRepositoryProvider);
  return BusinessNotifier(repository);
});
