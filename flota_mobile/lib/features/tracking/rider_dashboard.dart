import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flota_mobile/features/tracking/rider_dashboard_controller.dart';
import 'package:flota_mobile/features/tracking/rider_stats_service.dart';

class RiderDashboard extends ConsumerStatefulWidget {
  const RiderDashboard({super.key});

  @override
  ConsumerState<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends ConsumerState<RiderDashboard> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    // Start listening to location updates immediately
    LocationService.getPositionStream().listen((position) {
      if (mounted) {
        final latLng = LatLng(position.latitude, position.longitude);
        ref.read(riderDashboardControllerProvider.notifier).updateLocation(latLng);
        
        // If we want to follow the rider on the map:
        final state = ref.read(riderDashboardControllerProvider);
        if (state.isOnline) {
           _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderDashboardControllerProvider);
    final controller = ref.read(riderDashboardControllerProvider.notifier);
    final stats = state.stats;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // Prevent map resize on keyboard
      body: Stack(
        children: [
          // 1. Map Layer (Background)
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: state.currentLocation ?? const LatLng(6.5244, 3.3792), // Default Lagos
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) {
              _mapController = c;
              if (_mapStyle != null) {
                // ignore: invalid_use_of_protected_member
                c.setMapStyle(_mapStyle);
              }
            },
            tileOverlays: state.heatmapTileOverlay != null ? {state.heatmapTileOverlay!} : {},
          ),

          // 2. Performance & Heatmap Overlays (Middle Layer)
          Positioned(
             top: 140, 
             left: 20, 
             child: (state.isOnline && state.heatmapTileOverlay != null) 
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.local_fire_department, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text("High Demand Area", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                )
              : const SizedBox(),
          ),

          // 3. Control Center Header (Top Layer)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ControlCenterHeader(
              isOnline: state.isOnline,
              onToggleStatus: (val) => controller.toggleOnlineStatus(val),
            ),
          ),

          // 4. Safety FAB (Top Right)
          Positioned(
            top: 60,
            right: 20,
            child: SafeArea(
              child: FloatingActionButton.small(
                backgroundColor: Colors.white,
                child: const Icon(Icons.shield_outlined, color: AppTheme.primaryBlue),
                onPressed: () {
                  showModalBottomSheet(
                    context: context, 
                    backgroundColor: Colors.transparent,
                    builder: (_) => const _SafetyToolkitSheet()
                  );
                },
              )
            ),
          ),

          // 5. Draggable Sheet (Bottom Layer)
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
               return true;
            },
            child: DraggableScrollableSheet(
              initialChildSize: 0.40,
              minChildSize: 0.25,
              maxChildSize: 0.85, 
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5)),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        
                        // Earnings Section (Always Visible)
                        if (stats != null)
                          _EarningsHeader(
                            stats: stats,
                            isVisible: state.isEarningsVisible,
                            onToggleVisibility: controller.toggleEarningsVisibility,
                          )
                        else if (state.isLoading)
                          const Center(child: CircularProgressIndicator())
                        else 
                          const Center(child: Text("Unable to load stats")),
                        
                        const SizedBox(height: 25),
                        
                        // Quick Actions Grid
                        Row(
                          children: [
                            Expanded(child: _ActionBtn(icon: Icons.account_balance_wallet, label: "Wallet", onTap: () => context.push('/wallet'))),
                            const SizedBox(width: 10),
                            Expanded(child: _ActionBtn(icon: Icons.list_alt, label: "Jobs", onTap: () => context.push('/rider/jobs'))),
                            const SizedBox(width: 10),
                            Expanded(child: _ActionBtn(icon: Icons.insights, label: "Insights", onTap: () => context.push('/rider/earnings'))),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Job Radar / Feed
                        const Text("Nearby Opportunities", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 15),
                        
                        state.isOnline 
                          ? _JobRadarList(
                              jobs: state.nearbyJobs, 
                              isLoading: state.isLoading && state.nearbyJobs.isEmpty,
                              scrollController: scrollController,
                              currencySymbol: stats?.currencySymbol ?? '₦',
                            )
                          : _OfflineStateWidget(onGoOnline: () => controller.toggleOnlineStatus(true)),

                        const SizedBox(height: 30),

                        // Productivity & News
                         if (stats?.productivityTips.isNotEmpty == true) ...[
                           const Text("For You", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                           const SizedBox(height: 10),
                           _TipCard(tip: stats!.productivityTips.first),
                         ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Helper Widgets ----------------

class _ControlCenterHeader extends StatelessWidget {
  final bool isOnline;
  final Function(bool) onToggleStatus;

  const _ControlCenterHeader({required this.isOnline, required this.onToggleStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Vehicle Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.directions_car, size: 16, color: Colors.black87),
                SizedBox(width: 6),
                Text("Toyota Camry • ABJ-123", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Icon(Icons.arrow_drop_down, size: 16),
              ],
            ),
          ),

          // Status Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: isOnline ? Colors.white : Colors.black54,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                if (isOnline) const Padding(
                  padding: EdgeInsets.only(left: 10, right: 6),
                  child: Text("ONLINE", style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.successGreen, fontSize: 12)),
                ),
                Switch(
                  value: isOnline,
                  onChanged: onToggleStatus,
                  activeColor: AppTheme.successGreen,
                  activeTrackColor: Colors.grey[200],
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey,
                ),
                if (!isOnline) const Padding(
                  padding: EdgeInsets.only(left: 6, right: 10),
                  child: Text("OFFLINE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsHeader extends StatelessWidget {
  final RiderStats stats;
  final bool isVisible;
  final VoidCallback onToggleVisibility;

  const _EarningsHeader({required this.stats, required this.isVisible, required this.onToggleVisibility});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("Today's Earnings", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onToggleVisibility,
                      child: Icon(
                        isVisible ? Icons.visibility : Icons.visibility_off,
                        size: 18, 
                        color: Colors.grey[400]
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isVisible 
                    ? '${stats.currencySymbol}${stats.todaysEarnings.toStringAsFixed(2)}'
                    : '****',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            // Daily Goal Ring
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: (stats.todaysEarnings / (stats.shiftGoalTarget == 0 ? 1 : stats.shiftGoalTarget)).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                    strokeWidth: 5,
                  ),
                ),
                Text(
                  "${((stats.todaysEarnings / (stats.shiftGoalTarget == 0 ? 1 : stats.shiftGoalTarget)) * 100).toInt()}%",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                )
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _JobRadarList extends StatelessWidget {
  final List<JobOpportunity> jobs;
  final bool isLoading;
  final ScrollController scrollController;
  final String currencySymbol;

  const _JobRadarList({
    required this.jobs, 
    required this.isLoading, 
    required this.scrollController,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }

    if (jobs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            const Icon(Icons.radar, size: 40, color: Colors.grey),
            const SizedBox(height: 10),
            const Text("Scanning for jobs...", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Move to a high demand area", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(), // Handled by sheet
      shrinkWrap: true,
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              child: const Icon(Icons.local_shipping, color: AppTheme.primaryBlue),
            ),
            title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${job.distance} • ${job.location}", maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("$currencySymbol${job.earnings.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const Text("Est. earn", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            onTap: () {
              // Accept or View Job
            },
          ),
        );
      },
    );
  }
}

class _OfflineStateWidget extends StatelessWidget {
  final VoidCallback onGoOnline;

  const _OfflineStateWidget({required this.onGoOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      color: Colors.grey[50],
      child: Column(
        children: [
          const Icon(Icons.offline_bolt, size: 50, color: Colors.grey),
          const SizedBox(height: 15),
          const Text("You are Offline", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("Go online to start receiving orders", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onGoOnline,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text("GO ONLINE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryBlue),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _SafetyToolkitSheet extends StatelessWidget {
  const _SafetyToolkitSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Safety Toolkit", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.sos, color: Colors.white)),
            title: const Text("Emergency Assistance", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            subtitle: const Text("Call police or emergency services"),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.share, color: Colors.white)),
            title: const Text("Share My Trip"),
            subtitle: const Text("Share live location with trusted contacts"),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.warning, color: Colors.white)),
            title: const Text("Report Incident"),
            subtitle: const Text("Report an accident or safety issue"),
            onTap: () {},
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String tip;
  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: AppTheme.primaryBlue),
          const SizedBox(width: 15),
          Expanded(child: Text(tip, style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

// Minimal Map Style (Optional)
const String _mapStyle = '''
[]
''';
