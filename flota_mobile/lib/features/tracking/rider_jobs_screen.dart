import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/api_client.dart';

// Provider for fetching rider jobs
final riderJobsProvider = FutureProvider<List<RiderJob>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.dio.get('deliveries');
    final List deliveries = response.data['data'] ?? response.data ?? [];
    return deliveries.map((d) => RiderJob.fromJson(d)).toList();
  } catch (e) {
    return [];
  }
});

class RiderJob {
  final String id;
  final String pickupAddress;
  final String deliveryAddress;
  final String status;
  final double fare;
  final String? createdAt;
  final String parcelType;

  RiderJob({
    required this.id,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.status,
    required this.fare,
    this.createdAt,
    required this.parcelType,
  });

  factory RiderJob.fromJson(Map<String, dynamic> json) {
    return RiderJob(
      id: json['id']?.toString() ?? '',
      pickupAddress: json['pickup_address'] ?? 'Unknown Pickup',
      deliveryAddress: json['delivery_address'] ?? 'Unknown Destination',
      status: json['status'] ?? 'pending',
      fare: (json['fare'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'],
      parcelType: json['parcel_type'] ?? 'Parcel',
    );
  }
}

enum DispatchMode { orders, errands }

class RiderJobsScreen extends ConsumerStatefulWidget {
  const RiderJobsScreen({super.key});

  @override
  ConsumerState<RiderJobsScreen> createState() => _RiderJobsScreenState();
}

class _RiderJobsScreenState extends ConsumerState<RiderJobsScreen> with SingleTickerProviderStateMixin {
  DispatchMode _activeMode = DispatchMode.orders;
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(riderJobsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Glassmorphism Dispatcher Header
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.surfaceColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.8),
                      AppTheme.backgroundColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      _RadarScanner(controller: _radarController),
                      const SizedBox(height: 12),
                      Text(
                        'DISPATCH CENTER',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: _buildModeToggle(),
            ),
          ),

          // Job List
          jobsAsync.when(
            data: (jobs) {
              final filteredJobs = _getFilteredJobs(jobs);
              if (filteredJobs.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ModernJobCard(job: filteredJobs[index]),
                    childCount: filteredJobs.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load jobs',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check your connection and try again.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => ref.refresh(riderJobsProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderBlue),
      ),
      child: Row(
        children: DispatchMode.values.map((mode) {
          final isActive = _activeMode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeMode = mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    mode.name.toUpperCase(),
                    style: TextStyle(
                      color: isActive ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<RiderJob> _getFilteredJobs(List<RiderJob> jobs) {
    if (_activeMode == DispatchMode.orders) {
      // Filter for standard parcels/deliveries
      return jobs.where((j) => j.parcelType.toLowerCase() != 'errand').toList();
    } else {
      // Filter for specific errand requests
      return jobs.where((j) => j.parcelType.toLowerCase() == 'errand').toList();
    }
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.radar, size: 64, color: AppTheme.borderBlue.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(
          'SCANNING FOR ${_activeMode.name.toUpperCase()}...',
          style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _RadarScanner extends StatelessWidget {
  final AnimationController controller;
  const _RadarScanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryRed.withOpacity(1 - controller.value), width: 2),
          ),
          child: Center(
            child: Container(
              width: 40 * controller.value,
              height: 40 * controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryRed.withOpacity(0.3 * (1 - controller.value)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModernJobCard extends StatelessWidget {
  final RiderJob job;
  const _ModernJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final currency = "£"; // Defaulting to UK theme
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ID: #${job.id}',
                  style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Text(
                '$currency${job.fare.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Route Visualizer (Styled)
          _RouteVisualizer(pickup: job.pickupAddress, destination: job.deliveryAddress),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('ACCEPT JOB'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.info_outline, color: Colors.white70),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteVisualizer extends StatelessWidget {
  final String pickup;
  final String destination;

  const _RouteVisualizer({required this.pickup, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RouteNode(icon: Icons.circle, color: AppTheme.successGreen, address: pickup, label: 'PICKUP'),
        Padding(
          padding: const EdgeInsets.only(left: 11),
          child: Container(
            width: 2,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.successGreen, AppTheme.primaryRed],
              ),
            ),
          ),
        ),
        _RouteNode(icon: Icons.location_on, color: AppTheme.primaryRed, address: destination, label: 'DESTINATION'),
      ],
    );
  }
}

class _RouteNode extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String address;
  final String label;

  const _RouteNode({required this.icon, required this.color, required this.address, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
