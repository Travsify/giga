import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ParcelLockerScreen extends StatefulWidget {
  const ParcelLockerScreen({super.key});

  @override
  State<ParcelLockerScreen> createState() => _ParcelLockerScreenState();
}

class _ParcelLockerScreenState extends State<ParcelLockerScreen> {
  final Set<Marker> _markers = {
    Marker(
      markerId: const MarkerId('locker1'),
      position: const LatLng(51.5074, -0.1278), // London
      infoWindow: const InfoWindow(title: 'InPost Locker - Charing Cross'),
    ),
    Marker(
      markerId: const MarkerId('locker2'),
      position: const LatLng(51.5152, -0.1419), // Regent St
      infoWindow: const InfoWindow(title: 'Amazon Hub Locker - Carnaby'),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Parcel Locker', style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(51.5074, -0.1278),
              zoom: 14,
            ),
            markers: _markers,
            myLocationEnabled: true,
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Choose a nearby locker',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Select a pin on the map to see locker details.'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, 'locker1'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Confirm Locker'),
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
