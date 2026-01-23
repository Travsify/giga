import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flota_mobile/theme/app_theme.dart';

class LockerMapScreen extends StatefulWidget {
  const LockerMapScreen({super.key});

  @override
  State<LockerMapScreen> createState() => _LockerMapScreenState();
}

class _LockerMapScreenState extends State<LockerMapScreen> {
  static const LatLng _center = LatLng(51.5074, -0.1278); // London
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  void _loadMarkers() {
    setState(() {
      _markers.addAll([
        const Marker(
          markerId: MarkerId('locker_1'),
          position: LatLng(51.5074, -0.1278),
          infoWindow: InfoWindow(title: 'Giga Locker - Trafalgar'),
        ),
        const Marker(
          markerId: MarkerId('locker_2'),
          position: LatLng(51.5155, -0.1419),
          infoWindow: InfoWindow(title: 'Giga Locker - Oxford Circus'),
        ),
        const Marker(
          markerId: MarkerId('locker_3'),
          position: LatLng(51.5045, -0.0865),
          infoWindow: InfoWindow(title: 'Giga Locker - Shard'),
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Locker', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _center, zoom: 12),
            markers: _markers,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Giga Lockers are open 24/7. Use your QR code to unlock.'),
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
