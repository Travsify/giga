import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/websocket_service.dart';

class TrackingScreen extends StatefulWidget {
  final int deliveryId;
  final LatLng pickupLocation;
  final LatLng dropoffLocation;

  const TrackingScreen({
    super.key,
    this.deliveryId = 0, // Default for testing
    this.pickupLocation = const LatLng(6.5244, 3.3792), // Default pickup
    this.dropoffLocation = const LatLng(6.4281, 3.4219), // Default dropoff
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _markers = {};
  LatLng? _riderLocation;
  String _status = 'Rider assigned';
  String _eta = '15 mins';

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _setupMarkers();
  }

  void _connectWebSocket() {
    // Join delivery room
    WebSocketService.joinDeliveryRoom(widget.deliveryId);

    // Listen for rider updates
    WebSocketService.onRiderLocationUpdate((data) {
      if (mounted) {
        setState(() {
          _riderLocation = LatLng(data['lat'], data['lng']);
          _updateRiderMarker();
        });
      }
    });

    // Listen for status updates
    WebSocketService.onDeliveryStatusUpdate((data) {
      if (mounted) {
        setState(() {
          _status = data['status'];
          _eta = data['eta'] ?? _eta;
        });
      }
    });
  }

  void _setupMarkers() {
    _markers[const MarkerId('pickup')] = Marker(
      markerId: const MarkerId('pickup'),
      position: widget.pickupLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(title: 'Pickup Location'),
    );

    _markers[const MarkerId('dropoff')] = Marker(
      markerId: const MarkerId('dropoff'),
      position: widget.dropoffLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Dropoff Location'),
    );
  }

  void _updateRiderMarker() {
    if (_riderLocation == null) return;
    
    setState(() {
      _markers[const MarkerId('rider')] = Marker(
        markerId: const MarkerId('rider'),
        position: _riderLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Rider Location'),
        rotation: 0, // Could add heading if available
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(_riderLocation!),
    );
  }

  @override
  void dispose() {
    WebSocketService.leaveDeliveryRoom(widget.deliveryId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
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
                  const Icon(Icons.notifications, color: Colors.white, size: 28),
                ],
              ),
            ),
          ),

          // Driver Status Bar
          Positioned(
            top: 105,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: AppTheme.primaryRed,
              child: const Center(
                child: Text(
                  'Driver is 5 mins away',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),

          // Map Section
          Positioned.fill(
            top: 155,
            bottom: 120,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.pickupLocation,
                zoom: 14,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: Set<Marker>.of(_markers.values),
              // Polyline logic would go here for the red/blue route
            ),
          ),
          
          // Back Button
          Positioned(
            top: 170,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Driver Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=alex'),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alex Carter',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            ...List.generate(5, (index) => const Icon(Icons.star, color: Colors.orange, size: 18)),
                            const SizedBox(width: 8),
                            const Text(
                              '4.8',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 20),
                        const Text(
                          'Red Van • License Plate: AB123CD',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isActive;

  const _TrackStep({
    required this.title, 
    required this.subtitle,
    this.isDone = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppTheme.successGreen : (isActive ? AppTheme.primaryBlue : AppTheme.slateBlue.withOpacity(0.3)),
              ),
              child: isDone ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
            Container(width: 2, height: 20, color: Colors.white12),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppTheme.primaryBlue : (isDone ? Colors.white : AppTheme.slateBlue),
                ),
              ),
              Text(subtitle, style: const TextStyle(color: AppTheme.slateBlue, fontSize: 12)),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
