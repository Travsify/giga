import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:flota_mobile/features/business/business_provider.dart';

class FleetManagementScreen extends ConsumerStatefulWidget {
  const FleetManagementScreen({super.key});

  @override
  ConsumerState<FleetManagementScreen> createState() => _FleetManagementScreenState();
}

class _FleetManagementScreenState extends ConsumerState<FleetManagementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(businessProvider.notifier).fetchFleetDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final businessState = ref.watch(businessProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Fleet OS Command Center',
          style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryBlue),
            onPressed: () => ref.read(businessProvider.notifier).fetchFleetDashboard(),
          ),
        ],
      ),
      body: businessState.isLoading && businessState.fleetStats == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(businessProvider.notifier).fetchFleetDashboard(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFleetMetrics(businessState.fleetStats, authState),
                    const SizedBox(height: 32),
                    _buildDispatchActions(context),
                    const SizedBox(height: 32),
                    _buildLiveRidersList(businessState.fleetRiders),
                    const SizedBox(height: 32),
                    _buildRecentFleetActivity(businessState.recentActivity),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFleetMetrics(Map<String, dynamic>? stats, AuthState auth) {
    final currencySymbol = auth.currencySymbol;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fleet Performance',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4, // Slightly taller
          children: [
            _MetricTile(
              label: 'Total Riders',
              value: stats?['total_riders']?.toString() ?? '0',
              icon: Icons.people_rounded,
              color: AppTheme.primaryBlue,
            ),
            _MetricTile(
              label: 'Online Now',
              value: stats?['online_riders']?.toString() ?? '0',
              icon: Icons.online_prediction_rounded,
              color: Colors.green,
            ),
            _MetricTile(
              label: 'Fleet Revenue',
              value: '$currencySymbol${stats?['total_fleet_earnings']?.toStringAsFixed(0) ?? '0'}',
              icon: Icons.payments_rounded,
              color: Colors.orange,
            ),
            _MetricTile(
              label: 'Active Jobs',
              value: stats?['active_deliveries']?.toString() ?? '0',
              icon: Icons.local_shipping_rounded,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDispatchActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fleet Operations',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionSquare(
                label: 'Onboard Rider',
                icon: Icons.person_add_rounded,
                color: AppTheme.primaryBlue,
                onTap: () => context.push('/business/fleet/onboard'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionSquare(
                label: 'Broadcast',
                icon: Icons.campaign_rounded,
                color: Colors.deepOrange,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionSquare(
                label: 'Settle Payouts',
                icon: Icons.account_balance_rounded,
                color: Colors.teal,
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveRidersList(List<dynamic>? riders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Riders',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: Text('View All', style: GoogleFonts.outfit(color: AppTheme.primaryBlue)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (riders == null || riders.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.no_accounts_rounded, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No riders onboarded yet', style: GoogleFonts.outfit(color: Colors.grey[500])),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: riders.length > 5 ? 5 : riders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final rider = riders[index];
              final user = rider['user'];
              final isOnline = rider['is_online'] == true;
              
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: (isOnline ? Colors.green : Colors.grey).withOpacity(0.1),
                      child: Icon(Icons.person, color: isOnline ? Colors.green : Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['name'] ?? 'Unknown', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(rider['vehicle_plate_number'] ?? 'No Plate', style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isOnline ? Colors.green : Colors.grey[400]!).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOnline ? 'ONLINE' : 'OFFLINE',
                        style: GoogleFonts.outfit(
                          color: isOnline ? Colors.green : Colors.grey[600],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRecentFleetActivity(List<dynamic>? activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Fleet Activity',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: activity == null || activity.isEmpty
              ? const Center(child: Text('No recent activity'))
              : Column(
                  children: activity.map((job) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delivery_dining_rounded, size: 20, color: AppTheme.primaryBlue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Delivery ${job['status']?.toUpperCase()}', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text(job['dropoff_address'] ?? 'No address', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12)),
                              ],
                            ),
                          ),
                          Text('\$${job['fare']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(label, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}

class _ActionSquare extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionSquare({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Wrap content
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
          ],
        ),
      ),
    );
  }
}
