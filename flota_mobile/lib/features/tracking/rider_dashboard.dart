import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/location_service.dart';
import 'package:flota_mobile/core/error_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';

class RiderDashboard extends ConsumerStatefulWidget {
  const RiderDashboard({super.key});

  @override
  ConsumerState<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends ConsumerState<RiderDashboard> {
  bool isOnline = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _toggleOnline(bool value) {
    setState(() => isOnline = value);
    
    if (isOnline) {
      _startLocationUpdates();
      // No manual fetch needed, StreamBuilder handles it
    }
  }

  void _startLocationUpdates() {
    LocationService.getPositionStream().listen((position) {
      if (isOnline) {
        // Here we would write to Firestore 'riders' collection
        // FirebaseFirestore.instance.collection('riders').doc(ID).update(...)
        if (mounted) {
          setState(() => _currentPosition = position);
        }
      }
    });
  }

  Future<void> _acceptRequest(String id) async {
    try {
      await FirebaseFirestore.instance.collection('deliveries').doc(id).update({
        'status': 'accepted',
        'rider_id': 'CURRENT_USER_ID', // Replace with Auth ID
        'accepted_at': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Delivery Accepted!'), backgroundColor: AppTheme.successGreen),
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.handleError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom Top Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            color: AppTheme.primaryBlue,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Giga',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'Go Online',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Switch(
                      value: isOnline,
                      onChanged: _toggleOnline,
                      activeColor: Colors.green,
                      activeTrackColor: Colors.white.withOpacity(0.3),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Map with Heatmap Placeholder
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                 Image.asset(
                  'assets/images/heatmap_placeholder.png', 
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.blue[50],
                    child: const Center(child: Icon(Icons.wb_sunny_outlined, size: 80, color: Colors.blueAccent)),
                  ),
                ),
                // "You" marker overlay
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('You', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppTheme.primaryBlue, size: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Cards
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFFF1F4FA),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Today\'s Earnings',
                          value: '${ref.watch(authProvider).currencySymbol}128.50',
                          actionLabel: 'View Details',
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _StatCard(
                          title: 'Completed Jobs',
                          value: '8',
                          actionLabel: 'View History',
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 3) context.push('/profile');
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String actionLabel;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.actionLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Divider(height: 30),
          Row(
            children: [
              Text(
                actionLabel,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
