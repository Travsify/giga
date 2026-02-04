import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flota_mobile/features/tracking/rider_dashboard_controller.dart';
import 'package:flota_mobile/features/tracking/rider_stats_service.dart';
import 'package:flota_mobile/features/tracking/rider_earnings_screen.dart';
import 'package:flota_mobile/features/tracking/rider_jobs_screen.dart';
import 'package:flota_mobile/features/profile/profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class RiderDashboard extends ConsumerStatefulWidget {
  const RiderDashboard({super.key});

  @override
  ConsumerState<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends ConsumerState<RiderDashboard> {
  int _currentIndex = 0;

  // Tabs for the Bottom Navigation
  final List<Widget> _tabs = [
    const _RiderHomeTab(),
    const RiderEarningsScreen(),
    const RiderJobsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Earnings'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Jobs'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ---------------- HOME TAB (Map Command Center) ----------------
class _RiderHomeTab extends ConsumerStatefulWidget {
  const _RiderHomeTab();

  @override
  ConsumerState<_RiderHomeTab> createState() => _RiderHomeTabState();
}

class _RiderHomeTabState extends ConsumerState<_RiderHomeTab> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    // Start listening to location updates immediately
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      // Trigger permission prompt
      await LocationService.getCurrentLocation();
    } catch (e) {
      debugPrint('Location Init Error: $e');
    }

    LocationService.getPositionStream().listen((position) {
      if (mounted) {
        final latLng = LatLng(position.latitude, position.longitude);
        ref.read(riderDashboardControllerProvider.notifier).updateLocation(latLng);
        
        // Follow rider on map if online or first update
        _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderDashboardControllerProvider);
    final controller = ref.read(riderDashboardControllerProvider.notifier);
    final stats = state.stats;

    // Use default location (Lagos/London) if none available
    final initialPos = state.currentLocation ?? const LatLng(6.5244, 3.3792);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Layer
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: initialPos,
              zoom: 15,
            ),
            onMapCreated: (c) {
              _mapController = c;
              if (_mapStyle != null) {
                try {
                   c.setMapStyle(_mapStyle);
                } catch(e) {
                   debugPrint('Map style error: $e');
                }
              }
            },
            myLocationEnabled: true, // Always true if permission granted
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            markers: {}, // Add job markers later
            tileOverlays: state.heatmapTileOverlay != null ? {state.heatmapTileOverlay!} : {},
          ),

          // 2. Control Center Header (Floating)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ControlCenterHeader(
              isOnline: state.isOnline,
              onToggleStatus: controller.toggleOnlineStatus,
            ),
          ),

          // 3. Safety FAB
          Positioned(
            top: 100, // Below header
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'safety_fab',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.shield, color: AppTheme.primaryRed),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const _SafetyToolkitSheet(),
                    );
                  },
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'wallet_fab',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.account_balance_wallet, color: AppTheme.primaryBlue),
                  onPressed: () => context.push('/wallet'),
                ),
              ],
            ),
          ),

          // 4. "Go Online" Pill Button (if Offline) or Status Pill (if Online)
          Positioned(
            bottom: 30, // Above BottomNav
            left: 0,
            right: 0,
            child: Center(
              child: _StatusPill(
                isOnline: state.isOnline,
                onToggle: () => controller.toggleOnlineStatus(!state.isOnline),
              ),
            ),
          ),

          // 5. Loading Indicator
          if (state.isLoading)
             Container(
               color: Colors.black12,
               child: const Center(child: CircularProgressIndicator()),
             ),
        ],
      ),
    );
  }
}

// ---------------- HELPER WIDGETS ----------------

class _StatusPill extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onToggle;

  const _StatusPill({required this.isOnline, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isOnline ? Colors.white : AppTheme.primaryRed,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOnline) ...[
                const Icon(Icons.circle, color: AppTheme.successGreen, size: 12),
                const SizedBox(width: 8),
                Text("YOU ARE ONLINE", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            ] else ...[
                const Text("GO ONLINE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                const SizedBox(width: 8),
                const Icon(Icons.power_settings_new, color: Colors.white, size: 20),
            ]
          ],
        ),
      ),
    );
  }
}

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
            AppTheme.primaryBlue.withOpacity(0.9),
            AppTheme.primaryBlue.withOpacity(0.0), // Fade out
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           // Profile / Greeting
           Row(
             children: [
               const CircleAvatar(
                 backgroundColor: Colors.white24,
                 child: Icon(Icons.person, color: Colors.white),
               ),
               const SizedBox(width: 10),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text("Giga Rider", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                   Text(isOnline ? "Active" : "Offline", style: TextStyle(color: isOnline ? AppTheme.successGreen : Colors.white70, fontSize: 12)),
                 ],
               )
             ],
           ),

           // Vehicle Selector
           GestureDetector(
             onTap: () {
               // Show Vehicle Switcher
               showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Select Active Vehicle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      ListTile(
                        leading: const Icon(Icons.directions_car),
                        title: const Text("Toyota Camry • ABJ-123"),
                        trailing: const Icon(Icons.check_circle, color: AppTheme.primaryBlue),
                        onTap: () => Navigator.pop(context),
                      ),
                      ListTile(
                        leading: const Icon(Icons.motorcycle),
                        title: const Text("Honda Ace • KJA-456"),
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              );
             },
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(
                 color: Colors.white.withOpacity(0.2),
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(color: Colors.white30),
               ),
               child: const Row(
                 children: [
                   Icon(Icons.directions_car, size: 16, color: Colors.white),
                   SizedBox(width: 6),
                   Text("Toyota Camry", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                   Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
                 ],
               ),
             ),
           ),
        ],
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
            onTap: () async {
              final Uri launchUri = Uri(scheme: 'tel', path: '112');
              try {
                if (await canLaunchUrl(launchUri)) {
                  await launchUrl(launchUri);
                }
              } catch (e) {
                debugPrint('Error launching dialer: $e');
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.share, color: Colors.white)),
            title: const Text("Share My Trip"),
            subtitle: const Text("Share live location with trusted contacts"),
            onTap: () {
              Share.share('I am currently online and delivering with Giga. My location is secure.');
            },
          ),
          const Divider(),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.warning, color: Colors.white)),
            title: const Text("Report Incident"),
            subtitle: const Text("Report an accident or safety issue"),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Incident Reporting feature coming soon")),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Minimal Map Style
const String _mapStyle = '''
[
  { "elementType": "geometry", "stylers": [ { "color": "#121212" } ] },
  { "elementType": "labels.icon", "stylers": [ { "visibility": "off" } ] },
  { "elementType": "labels.text.fill", "stylers": [ { "color": "#757575" } ] },
  { "elementType": "labels.text.stroke", "stylers": [ { "color": "#121212" } ] },
  { "featureType": "administrative", "elementType": "geometry", "stylers": [ { "color": "#757575" } ] },
  { "featureType": "administrative.country", "elementType": "labels.text.fill", "stylers": [ { "color": "#9e9e9e" } ] },
  { "featureType": "administrative.land_parcel", "stylers": [ { "visibility": "off" } ] },
  { "featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [ { "color": "#bdbdbd" } ] },
  { "featureType": "poi", "elementType": "labels.text.fill", "stylers": [ { "color": "#757575" } ] },
  { "featureType": "poi.park", "elementType": "geometry", "stylers": [ { "color": "#181818" } ] },
  { "featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [ { "color": "#616161" } ] },
  { "featureType": "poi.park", "elementType": "labels.text.stroke", "stylers": [ { "color": "#1b1b1b" } ] },
  { "featureType": "road", "elementType": "geometry.fill", "stylers": [ { "color": "#2c2c2c" } ] },
  { "featureType": "road", "elementType": "labels.text.fill", "stylers": [ { "color": "#8a8a8a" } ] },
  { "featureType": "road.arterial", "elementType": "geometry", "stylers": [ { "color": "#373737" } ] },
  { "featureType": "road.highway", "elementType": "geometry", "stylers": [ { "color": "#3c3c3c" } ] },
  { "featureType": "road.highway.controlled_access", "elementType": "geometry", "stylers": [ { "color": "#4e4e4e" } ] },
  { "featureType": "road.local", "elementType": "labels.text.fill", "stylers": [ { "color": "#616161" } ] },
  { "featureType": "transit", "elementType": "labels.text.fill", "stylers": [ { "color": "#757575" } ] },
  { "featureType": "water", "elementType": "geometry", "stylers": [ { "color": "#000000" } ] },
  { "featureType": "water", "elementType": "labels.text.fill", "stylers": [ { "color": "#3d3d3d" } ] }
]
''';
