import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/api_client.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';

// 1. DATA MODELS & PROVIDERS

enum JobSegment { live, active, history }
enum DiscoveryMode { orders, errands }

class RiderJob {
  final String id;
  final String pickupAddress;
  final String deliveryAddress;
  final String status;
  final double fare;
  final String? createdAt;
  final String? updatedAt;
  final String parcelType;
  final String? description; // Errand instructions
  final Map<String, dynamic>? payoutBreakdown;
  final Map<String, dynamic>? customer;
  final List<dynamic>? stops;

  RiderJob({
    required this.id,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.status,
    required this.fare,
    this.createdAt,
    this.updatedAt,
    required this.parcelType,
    this.description,
    this.payoutBreakdown,
    this.customer,
    this.stops,
  });

  bool get isErrand => parcelType.toLowerCase() == 'errand';

  factory RiderJob.fromJson(Map<String, dynamic> json) {
    return RiderJob(
      id: json['id']?.toString() ?? '',
      pickupAddress: json['pickup_address'] ?? 'Unknown Pickup',
      deliveryAddress: json['delivery_address'] ?? 'Unknown Destination',
      status: json['status'] ?? 'pending',
      fare: (json['fare'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      parcelType: json['parcel_type'] ?? 'Parcel',
      description: json['description'],
      payoutBreakdown: json['payout_breakdown'],
      customer: json['customer'],
      stops: json['stops'],
    );
  }
}

// Live Jobs (Radar)
final riderLiveJobsProvider = FutureProvider.family<List<RiderJob>, String>((ref, mode) async {
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.dio.get('deliveries', queryParameters: {
      'status': 'pending',
      'parcel_type': mode,
    });
    final List deliveries = response.data['data'] ?? response.data ?? [];
    return deliveries.map((d) => RiderJob.fromJson(d)).toList();
  } catch (e) {
    return [];
  }
});

// Active Job
final riderActiveJobProvider = FutureProvider<RiderJob?>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.dio.get('rider/active-job');
    if (response.data['status'] == 'success' && response.data['data'] != null) {
      return RiderJob.fromJson(response.data['data']);
    }
    return null;
  } catch (e) {
    return null;
  }
});

// History
final riderHistoryJobsProvider = FutureProvider<List<RiderJob>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.dio.get('rider/history');
    final List deliveries = response.data['data']['data'] ?? response.data['data'] ?? [];
    return deliveries.map((d) => RiderJob.fromJson(d)).toList();
  } catch (e) {
    return [];
  }
});

// 2. MAIN UI SCREEN

class RiderJobsScreen extends ConsumerStatefulWidget {
  const RiderJobsScreen({super.key});

  @override
  ConsumerState<RiderJobsScreen> createState() => _RiderJobsScreenState();
}

class _RiderJobsScreenState extends ConsumerState<RiderJobsScreen> with SingleTickerProviderStateMixin {
  JobSegment _activeSegment = JobSegment.live;
  DiscoveryMode _discoveryMode = DiscoveryMode.orders;
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Dynamic Header with Segment Control
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.surfaceColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderBackground(),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: _buildSegmentControl(),
            ),
          ),

          // Content based on Segment
          _buildSegmentContent(),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return Container(
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
            if (_activeSegment == JobSegment.live)
              _RadarScanner(controller: _radarController)
            else
              const Icon(Icons.assignment_ind, size: 40, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              _activeSegment == JobSegment.live ? 'DISPATCH RADAR' : 
              _activeSegment == JobSegment.active ? 'ACTIVE MISSIONS' : 'JOB LOGS',
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
    );
  }

  Widget _buildSegmentControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderBlue),
      ),
      child: Row(
        children: JobSegment.values.map((segment) {
          final isActive = _activeSegment == segment;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeSegment = segment),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    segment.name.toUpperCase(),
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

  Widget _buildSegmentContent() {
    switch (_activeSegment) {
      case JobSegment.live:
        return _buildLiveList();
      case JobSegment.active:
        return _buildActiveView();
      case JobSegment.history:
        return _buildHistoryList();
    }
  }

  Widget _buildLiveList() {
    final liveJobsAsync = ref.watch(riderLiveJobsProvider(_discoveryMode.name));
    return liveJobsAsync.when(
      data: (jobs) {
        return SliverList(
          delegate: SliverChildListDelegate([
            _buildDiscoveryToggle(),
            if (jobs.isEmpty)
              SizedBox(
                height: 400,
                child: _buildEmptyState('SCANNING FOR ${_discoveryMode.name.toUpperCase()}...'),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: jobs.map((job) => _LiveJobCard(
                    job: job,
                    onAccept: () => _acceptJob(job),
                  )).toList(),
                ),
              ),
          ]),
        );
      },
      loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _buildErrorState('Live Jobs'),
    );
  }

  Widget _buildDiscoveryToggle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: DiscoveryMode.values.map((mode) {
          final isActive = _discoveryMode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _discoveryMode = mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryBlue.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        mode == DiscoveryMode.orders ? Icons.local_shipping_outlined : Icons.shopping_basket_outlined,
                        size: 14,
                        color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mode.name.toUpperCase(),
                        style: TextStyle(
                          color: isActive ? Colors.white : AppTheme.textSecondary,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          fontSize: 10,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveView() {
    final activeJobAsync = ref.watch(riderActiveJobProvider);
    return activeJobAsync.when(
      data: (job) {
        if (job == null) {
          return SliverFillRemaining(child: _buildEmptyState('NO ACTIVE JOBS'));
        }
        return SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: _ActiveJobCard(
              job: job,
              onUpdateStatus: (newStatus) => _updateJobStatus(job.id, newStatus),
              onNavigate: () => _navigateToMap(job),
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _buildErrorState('Active Job'),
    );
  }

  Future<void> _acceptJob(RiderJob job) async {
    final api = ref.read(apiClientProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final response = await api.dio.post('deliveries/${job.id}/accept');
      if (response.data['status'] == 'success') {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Job accepted! Switching to Active view.')),
        );
        if (!mounted) return;
        setState(() => _activeSegment = JobSegment.active);
        ref.invalidate(riderLiveJobsProvider(_discoveryMode.name));
        ref.invalidate(riderActiveJobProvider);
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateJobStatus(String jobId, String status) async {
    final api = ref.read(apiClientProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final response = await api.dio.patch('deliveries/$jobId/status', data: {'status': status});
      if (response.data['status'] == 'success') {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Status updated to ${status.replaceAll('_', ' ')}')),
        );
        if (!mounted) return;
        if (status == 'delivered') {
          setState(() => _activeSegment = JobSegment.history);
          ref.invalidate(riderHistoryJobsProvider);
        }
        ref.invalidate(riderActiveJobProvider);
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _navigateToMap(RiderJob job) {
    // In a real app, this would use a maps plugin or deep link
    // For now, we simulate opening navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redirecting to Google Maps...')),
    );
  }

  Widget _buildHistoryList() {
    final historyJobsAsync = ref.watch(riderHistoryJobsProvider);
    return historyJobsAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return SliverFillRemaining(child: _buildEmptyState('NO PAST DELIVERIES'));
        }
        return SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _HistoryJobCard(job: jobs[index]),
              childCount: jobs.length,
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _buildErrorState('History'),
    );
  }

  Widget _buildEmptyState(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.radar, size: 64, color: AppTheme.borderBlue.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(
          message,
          style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildErrorState(String section) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Unable to load $section',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (_activeSegment == JobSegment.live) {
                    ref.invalidate(riderLiveJobsProvider(_discoveryMode.name));
                  }
                  if (_activeSegment == JobSegment.active) {
                    ref.invalidate(riderActiveJobProvider);
                  }
                  if (_activeSegment == JobSegment.history) {
                    ref.invalidate(riderHistoryJobsProvider);
                  }
                },
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
    );
  }
}

// 3. SPECIALIZED UI COMPONENTS

class _LiveJobCard extends StatelessWidget {
  final RiderJob job;
  final VoidCallback onAccept;
  const _LiveJobCard({required this.job, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: job.isErrand ? AppTheme.accentCyan.withOpacity(0.5) : AppTheme.borderBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: job.isErrand ? AppTheme.accentCyan.withOpacity(0.2) : AppTheme.primaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  job.isErrand ? 'ERRAND' : 'ORDER',
                  style: TextStyle(
                    color: job.isErrand ? AppTheme.accentCyan : AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              Text(
                '£${job.fare.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (job.isErrand) ...[
            Text(
              'TASKS:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 1.0),
            ),
            const SizedBox(height: 4),
            Text(
              job.description ?? 'Personal request',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
          ],
          _RouteVisualizer(pickup: job.pickupAddress, destination: job.deliveryAddress),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: job.isErrand ? AppTheme.accentCyan : AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(job.isErrand ? 'ACCEPT ERRAND' : 'ACCEPT ORDER'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveJobCard extends StatelessWidget {
  final RiderJob job;
  final Function(String) onUpdateStatus;
  final VoidCallback onNavigate;
  const _ActiveJobCard({required this.job, required this.onUpdateStatus, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final nextStatusLabel = job.status == 'assigned' ? 'SWIPE TO PICK UP' : 
                          job.status == 'picked_up' ? 'SWIPE TO START TRIP' : 'SWIPE TO COMPLETE';
    
    final nextStatusValue = job.status == 'assigned' ? 'picked_up' : 
                          job.status == 'picked_up' ? 'in_transit' : 'delivered';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.successGreen, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.successGreen.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.directions_bike, color: AppTheme.successGreen),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ONGOING MISSION', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(
                      job.status == 'assigned' ? 'Head to Pickup Point' : 
                      job.status == 'picked_up' ? 'Parcel Securely Loaded' : 'In Transit to Destination',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _RouteVisualizer(pickup: job.pickupAddress, destination: job.deliveryAddress),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {}, // Chat logic in next phase
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('CHAT'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation, size: 18),
                  label: const Text('NAVIGATE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onUpdateStatus(nextStatusValue),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(nextStatusLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryJobCard extends StatelessWidget {
  final RiderJob job;
  const _HistoryJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderBlue),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: job.status == 'delivered' ? AppTheme.successGreen.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              job.isErrand ? Icons.shopping_basket : Icons.local_shipping,
              color: job.status == 'delivered' ? AppTheme.successGreen : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.id, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                Text(
                  job.deliveryAddress,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  job.isErrand ? 'Errand Request' : 'Standard Delivery',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '£${job.fare.toStringAsFixed(2)}',
                style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                job.status.toUpperCase(),
                style: TextStyle(
                  color: job.status == 'delivered' ? AppTheme.successGreen.withOpacity(0.6) : Colors.red.withOpacity(0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// SHARED UTILS

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
            height: 24,
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
