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
import 'package:flota_mobile/features/profile/verification_screen.dart';
import 'package:flota_mobile/features/tracking/rider_performance_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class RiderDashboard extends ConsumerStatefulWidget {
  const RiderDashboard({super.key});

  @override
  ConsumerState<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends ConsumerState<RiderDashboard> {
  int _currentIndex = 0;

  // Primary Tabs for the Dispatcher Console
  final List<Widget> _tabs = [
    const _RiderHomeTab(),
    const RiderJobsScreen(),
    const RiderEarningsScreen(),
    const RiderPerformanceScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: _buildBrandedFooter(),
    );
  }

  Widget _buildBrandedFooter() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: const Border(top: BorderSide(color: AppTheme.borderBlue, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _FooterItem(
                icon: Icons.radar,
                label: 'Home',
                isActive: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _FooterItem(
                icon: Icons.list_alt,
                label: 'Orders',
                isActive: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _FooterItem(
                icon: Icons.account_balance_wallet,
                label: 'Earnings',
                isActive: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _FooterItem(
                icon: Icons.insights,
                label: 'Insights',
                isActive: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
              _FooterItem(
                icon: Icons.person,
                label: 'Profile',
                isActive: _currentIndex == 4,
                onTap: () => setState(() => _currentIndex = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FooterItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppTheme.primaryRed : AppTheme.textSecondary,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _GigaCenterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GigaCenterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: const Icon(Icons.power_settings_new, color: Colors.white, size: 28),
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

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ControlCenterHeader(
              isOnline: state.isOnline,
              stats: stats,
              onToggleStatus: (val) => controller.toggleOnlineStatus(val),
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
  final RiderStats? stats;
  final Function(bool) onToggleStatus;

  const _ControlCenterHeader({required this.isOnline, this.stats, required this.onToggleStatus});

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
           GestureDetector(
             onTap: () => context.push('/profile'),
             child: Row(
               children: [
                 const CircleAvatar(
                   backgroundColor: AppTheme.primaryBlue,
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
           ),

            // Vehicle Selector / Verification Prompt
            GestureDetector(
              onTap: () {
                if (stats?.hasVehicle == true) {
                  // Show Vehicle Switcher
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => _buildVehicleSwitcher(context),
                  );
                } else {
                  // Navigate to Verification flow directly
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VerificationScreen()),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (stats?.isVerified == true) ? Colors.white.withOpacity(0.2) : AppTheme.primaryRed.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: Row(
                  children: [
                    Icon(
                      (stats?.hasVehicle == true) ? Icons.directions_car : Icons.add_circle_outline, 
                      size: 16, 
                      color: Colors.white
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (stats?.hasVehicle == true) ? "Standard Fleet" : "VERIFY NOW", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)
                    ),
                    if (stats?.hasVehicle == true) const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleSwitcher(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Select Active Vehicle", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 15),
          ListTile(
            leading: const Icon(Icons.directions_car, color: Colors.white),
            title: const Text("Giga Fleet • ABJ-123", style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.check_circle, color: AppTheme.primaryBlue),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.motorcycle, color: Colors.white),
            title: const Text("Honda Ace • KJA-456", style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
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
