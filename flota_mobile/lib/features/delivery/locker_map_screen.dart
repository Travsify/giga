import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/features/delivery/data/locker_repository.dart';

class LockerMapScreen extends ConsumerStatefulWidget {
  const LockerMapScreen({super.key});

  @override
  ConsumerState<LockerMapScreen> createState() => _LockerMapScreenState();
}

class _LockerMapScreenState extends ConsumerState<LockerMapScreen> {
  static const LatLng _center = LatLng(51.5074, -0.1278);
  GoogleMapController? _controller;

  Set<Marker> _buildMarkers(List<Locker> lockers) {
    return lockers.map((locker) {
      final color = locker.status == 'available' 
          ? BitmapDescriptor.hueGreen 
          : locker.status == 'full' 
              ? BitmapDescriptor.hueRed 
              : BitmapDescriptor.hueOrange;
      return Marker(
        markerId: MarkerId('locker_${locker.id}'),
        position: LatLng(locker.latitude, locker.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(color),
        infoWindow: InfoWindow(
          title: locker.name,
          snippet: '${locker.availableCompartments}/${locker.totalCompartments} available',
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final lockersAsync = ref.watch(lockersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Locker', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: lockersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (lockers) => Stack(
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(target: _center, zoom: 12),
              markers: _buildMarkers(lockers),
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              onMapCreated: (controller) => _controller = controller,
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Giga Lockers', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${lockers.length} locations • Open 24/7', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
