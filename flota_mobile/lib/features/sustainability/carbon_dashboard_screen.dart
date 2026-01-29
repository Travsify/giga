import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/core/api_client.dart';
import 'package:animate_do/animate_do.dart';

class SustainabilityStats {
  final double totalCo2SavedKg;
  final int ecoDeliveriesCount;
  final double distanceCycledKm;
  final int paperSavedSheets;
  final double treesEquivalent;

  SustainabilityStats({
    required this.totalCo2SavedKg,
    required this.ecoDeliveriesCount,
    required this.distanceCycledKm,
    required this.paperSavedSheets,
    required this.treesEquivalent,
  });

  factory SustainabilityStats.fromJson(Map<String, dynamic> json) {
    return SustainabilityStats(
      totalCo2SavedKg: (json['total_co2_saved_kg'] ?? 0).toDouble(),
      ecoDeliveriesCount: json['eco_deliveries_count'] ?? 0,
      distanceCycledKm: (json['distance_cycled_km'] ?? 0).toDouble(),
      paperSavedSheets: json['paper_saved_sheets'] ?? 0,
      treesEquivalent: (json['trees_equivalent'] ?? 0).toDouble(),
    );
  }
}

final sustainabilityStatsProvider = FutureProvider<SustainabilityStats>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.dio.get('/sustainability/stats');
  return SustainabilityStats.fromJson(response.data);
});

class CarbonDashboardScreen extends ConsumerWidget {
  const CarbonDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(sustainabilityStatsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Eco Impact', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              FadeInDown(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38ef7d).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.eco_rounded, color: Colors.white, size: 48),
                      const SizedBox(height: 10),
                      const Text(
                        'Total CO₂ Saved',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${stats.totalCo2SavedKg.toStringAsFixed(1)} kg',
                        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Equivalent to planting ${stats.treesEquivalent.toStringAsFixed(1)} trees 🌳',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              FadeInLeft(
                delay: const Duration(milliseconds: 200),
                child: _buildStatTile('Eco Deliveries', '${stats.ecoDeliveriesCount}', Icons.pedal_bike_rounded, Colors.green),
              ),
              const SizedBox(height: 15),
              FadeInRight(
                delay: const Duration(milliseconds: 300),
                child: _buildStatTile('Distance Cycled', '${stats.distanceCycledKm.toStringAsFixed(1)} km', Icons.directions_bike_rounded, Colors.orange),
              ),
              const SizedBox(height: 15),
              FadeInLeft(
                delay: const Duration(milliseconds: 400),
                child: _buildStatTile('Paper Saved', '${stats.paperSavedSheets} sheets', Icons.description_outlined, Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
