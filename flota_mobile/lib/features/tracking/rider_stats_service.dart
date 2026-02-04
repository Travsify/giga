import 'package:flota_mobile/core/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RiderStats {
  final double todaysEarnings;
  final int completedJobsToday;
  final int completionRate;
  final double shiftGoalTarget;
  final List<String> productivityTips; // Can be empty if backend returns null
  final String currency;
  final String currencySymbol;
  final double walletBalance;
  final int acceptanceRate;
  final double cancellationRate;
  final int onTimeRate;
  final double totalDistance;
  final List<Map<String, dynamic>> activity;
  final double rating;
  final bool isOnline;
  final int totalJobsCompleted;
  final double fareEarnings;
  final double tips;
  final double bonuses;

  RiderStats({
    required this.todaysEarnings,
    required this.completedJobsToday,
    required this.totalJobsCompleted,
    required this.completionRate,
    required this.shiftGoalTarget,
    required this.productivityTips,
    required this.currency,
    required this.currencySymbol,
    required this.walletBalance,
    required this.acceptanceRate,
    required this.cancellationRate,
    required this.onTimeRate,
    required this.totalDistance,
    required this.activity,
    required this.rating,
    required this.isOnline,
    required this.fareEarnings,
    required this.tips,
    required this.bonuses,
  });

  factory RiderStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return RiderStats(
      todaysEarnings: (data['todays_earnings'] as num?)?.toDouble() ?? 0.0,
      completedJobsToday: data['completed_jobs_today'] as int? ?? 0,
      totalJobsCompleted: data['total_jobs_completed'] as int? ?? 0,
      completionRate: data['completion_rate'] as int? ?? 0,
      shiftGoalTarget: (data['shift_goal_target'] as num?)?.toDouble() ?? 100.0,
      productivityTips: (data['productivity_tips'] as List?)?.map((e) => e.toString()).toList() ?? [],
      currency: data['currency'] as String? ?? 'GBP',
      currencySymbol: data['currency_symbol'] as String? ?? '£',
      walletBalance: (data['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      acceptanceRate: data['acceptance_rate'] as int? ?? 100,
      cancellationRate: (data['cancellation_rate'] as num?)?.toDouble() ?? 0.0,
      onTimeRate: data['on_time_rate'] as int? ?? 100,
      totalDistance: (data['total_distance'] as num?)?.toDouble() ?? 0.0,
      activity: List<Map<String, dynamic>>.from(data['activity'] ?? []),
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      isOnline: data['is_online'] as bool? ?? false,
      fareEarnings: (data['fare_earnings'] as num?)?.toDouble() ?? 0.0,
      tips: (data['tips'] as num?)?.toDouble() ?? 0.0,
      bonuses: (data['bonuses'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class JobOpportunity {
  final int id;
  final String title;
  final String location;
  final double earnings;
  final String distance;
  
  JobOpportunity({
    required this.id,
    required this.title,
    required this.location,
    required this.earnings,
    required this.distance,
  });

  factory JobOpportunity.fromJson(Map<String, dynamic> json) {
    return JobOpportunity(
      id: json['id'],
      title: json['title'] ?? 'Delivery Job',
      location: json['pickup_address'] ?? 'Unknown Location',
      earnings: (json['estimated_earnings'] as num?)?.toDouble() ?? 0.0,
      distance: json['distance_text'] ?? 'Nearby',
    );
  }
}

class RiderStatsService {
  final ApiClient _apiClient;

  RiderStatsService(this._apiClient);

  Future<RiderStats> getDashboardStats() async {
    try {
      final response = await _apiClient.dio.get('rider/dashboard-stats');
      if (response.statusCode == 200) {
        return RiderStats.fromJson(response.data);
      } else {
        throw Exception('Failed to load rider stats: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateRiderStatus(bool isOnline) async {
    try {
      final response = await _apiClient.dio.patch(
        'profile/rider',
        data: {'is_online': isOnline},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }

  Future<List<JobOpportunity>> getNearbyJobs() async {
    try {
      final response = await _apiClient.dio.get('deliveries', queryParameters: {'status': 'pending', 'nearby': 'true'});
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => JobOpportunity.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return []; // Return empty on error to act as empty state
    }
  }

  // Future feature: Heatmap
  Future<TileOverlay?> getHeatmapOverlay() async {
    // In production, fetch tile URL template from backend
    // return TileOverlay(tileOverlayId: TileOverlayId('heatmap'), tileProvider: UrlTileProvider(...));
    return null; 
  }
}

final riderStatsServiceProvider = Provider<RiderStatsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RiderStatsService(apiClient);
});

final riderStatsProvider = FutureProvider<RiderStats>((ref) async {
  final service = ref.watch(riderStatsServiceProvider);
  return service.getDashboardStats();
});
