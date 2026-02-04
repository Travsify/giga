import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/features/tracking/rider_stats_service.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RiderDashboardState {
  final bool isLoading;
  final bool isOnline;
  final bool isEarningsVisible;
  final RiderStats? stats;
  final List<JobOpportunity> nearbyJobs;
  final TileOverlay? heatmapTileOverlay;
  final String? error;
  final LatLng? currentLocation; // For map centering

  RiderDashboardState({
    this.isLoading = false,
    this.isOnline = false,
    this.isEarningsVisible = false, // Hidden by default for privacy
    this.stats,
    this.nearbyJobs = const [],
    this.heatmapTileOverlay,
    this.error,
    this.currentLocation,
  });

  RiderDashboardState copyWith({
    bool? isLoading,
    bool? isOnline,
    bool? isEarningsVisible,
    RiderStats? stats,
    List<JobOpportunity>? nearbyJobs,
    TileOverlay? heatmapTileOverlay,
    String? error,
    LatLng? currentLocation,
  }) {
    return RiderDashboardState(
      isLoading: isLoading ?? this.isLoading,
      isOnline: isOnline ?? this.isOnline,
      isEarningsVisible: isEarningsVisible ?? this.isEarningsVisible,
      stats: stats ?? this.stats,
      nearbyJobs: nearbyJobs ?? this.nearbyJobs,
      heatmapTileOverlay: heatmapTileOverlay ?? this.heatmapTileOverlay,
      error: error ?? this.error,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }
}

class RiderDashboardController extends StateNotifier<RiderDashboardState> {
  final RiderStatsService _statsService;

  RiderDashboardController(this._statsService) : super(RiderDashboardState()) {
    _init();
  }

  Future<void> _init() async {
    await fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final stats = await _statsService.getDashboardStats();
      // Only fetch jobs if online
      final jobs = state.isOnline ? await _statsService.getNearbyJobs() : <JobOpportunity>[];
      final heatmap = await _statsService.getHeatmapOverlay();

      state = state.copyWith(
        isLoading: false,
        stats: stats,
        nearbyJobs: jobs,
        heatmapTileOverlay: heatmap,
        isOnline: stats.isOnline, // Sync starting status
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleOnlineStatus(bool value) async {
    // Optimistic update
    final previousStatus = state.isOnline;
    state = state.copyWith(isOnline: value);

    try {
      await _statsService.updateRiderStatus(value);
      // Reload stats/jobs as they might change when going online
      if (value) {
         fetchDashboardData();
      } else {
        // Clear jobs if offline
        state = state.copyWith(nearbyJobs: []);
      }
    } catch (e) {
      // Revert on error
      print('Status Toggle Error: $e'); // Debug log
      state = state.copyWith(isOnline: previousStatus, error: "Failed to update status: $e");
    }
  }

  void toggleEarningsVisibility() {
    state = state.copyWith(isEarningsVisible: !state.isEarningsVisible);
  }

  void updateLocation(LatLng location) {
    state = state.copyWith(currentLocation: location);
  }
}

final riderDashboardControllerProvider = StateNotifierProvider<RiderDashboardController, RiderDashboardState>((ref) {
  final statsService = ref.watch(riderStatsServiceProvider);
  return RiderDashboardController(statsService);
});
