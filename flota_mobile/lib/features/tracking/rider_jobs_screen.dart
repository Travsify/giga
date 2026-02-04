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

  RiderJob({
    required this.id,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.status,
    required this.fare,
    this.createdAt,
  });

  factory RiderJob.fromJson(Map<String, dynamic> json) {
    return RiderJob(
      id: json['id']?.toString() ?? '',
      pickupAddress: json['pickup_address'] ?? 'Unknown Pickup',
      deliveryAddress: json['delivery_address'] ?? 'Unknown Destination',
      status: json['status'] ?? 'pending',
      fare: (json['fare'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'],
    );
  }
}

class RiderJobsScreen extends ConsumerStatefulWidget {
  const RiderJobsScreen({super.key});

  @override
  ConsumerState<RiderJobsScreen> createState() => _RiderJobsScreenState();
}

class _RiderJobsScreenState extends ConsumerState<RiderJobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(riderJobsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        title: Text(
          'My Jobs',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: null, // No back button for tab view
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: jobsAsync.when(
        data: (jobs) {
          final available = jobs.where((j) => j.status == 'pending' || j.status == 'available').toList();
          final active = jobs.where((j) => j.status == 'in_progress' || j.status == 'picked_up').toList();
          final completed = jobs.where((j) => j.status == 'delivered' || j.status == 'completed').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _JobList(jobs: available, emptyMessage: 'No available jobs right now', showAccept: true),
              _JobList(jobs: active, emptyMessage: 'No active jobs'),
              _JobList(jobs: completed, emptyMessage: 'No completed jobs yet'),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading jobs: $e')),
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  final List<RiderJob> jobs;
  final String emptyMessage;
  final bool showAccept;

  const _JobList({required this.jobs, required this.emptyMessage, this.showAccept = false});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, index) => _JobCard(job: jobs[index], showAccept: showAccept),
    );
  }
}

class _JobCard extends StatelessWidget {
  final RiderJob job;
  final bool showAccept;

  const _JobCard({required this.job, this.showAccept = false});

  Color _getStatusColor() {
    switch (job.status) {
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'in_progress':
      case 'picked_up':
        return Colors.orange;
      default:
        return AppTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Job #${job.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  job.status.toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(color: _getStatusColor(), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.circle, color: Colors.green, size: 12),
              const SizedBox(width: 8),
              Expanded(
                child: Text(job.pickupAddress, style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Container(width: 2, height: 20, color: Colors.grey[300]),
          ),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 12),
              const SizedBox(width: 8),
              Expanded(
                child: Text(job.deliveryAddress, style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('£${job.fare.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (showAccept)
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Job acceptance coming soon!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Accept', style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
