import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/location_service.dart';
import 'package:flota_mobile/features/marketplace/data/delivery_repository.dart';
import 'package:flota_mobile/features/marketplace/data/models/delivery_models.dart';

import 'package:flota_mobile/features/auth/auth_provider.dart';

class MultiStopScreen extends ConsumerStatefulWidget {
  const MultiStopScreen({super.key});

  @override
  ConsumerState<MultiStopScreen> createState() => _MultiStopScreenState();
}

class _MultiStopScreenState extends ConsumerState<MultiStopScreen> {
  final List<Map<String, dynamic>> _stops = [
    {'address': 'Pickup Point', 'type': 'pickup', 'position': null},
    {'address': 'Destination 1', 'type': 'dropoff', 'position': null},
  ];

  double _totalDistance = 0.0;
  double _apiFare = 0.0;
  bool _isEstimating = false;
  bool _isCreating = false;
  GoogleMapController? _mapController;

  Future<void> _getUserLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (mounted && _mapController != null) {
        // Only center on user if no stops have positions yet
        bool hasPositions = _stops.any((s) => s['position'] != null);
        if (!hasPositions) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude),
              15,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _calculateTotalDistance() async {
    double distance = 0.0;
    List<LatLng> positions = [];
    for (var stop in _stops) {
      if (stop['position'] != null) {
        positions.add(stop['position'] as LatLng);
      }
    }

    if (positions.length >= 2) {
      for (int i = 0; i < positions.length - 1; i++) {
        distance += LocationService.calculateDistance(
          positions[i].latitude,
          positions[i].longitude,
          positions[i+1].latitude,
          positions[i+1].longitude,
        );
      }
      
      setState(() {
        _totalDistance = distance;
        _isEstimating = true;
      });

      try {
        final repository = ref.read(deliveryRepositoryProvider);
        final request = DeliveryEstimationRequest(
          pickupLat: positions.first.latitude,
          pickupLng: positions.first.longitude,
          dropoffLat: positions.last.latitude,
          dropoffLng: positions.last.longitude,
          vehicleType: 'Van', // Default, could be a selector
          serviceTier: 'Standard',
          stops: _stops.asMap().entries.map((e) => DeliveryStopModel(
            address: e.value['address'],
            lat: e.value['position']?.latitude ?? 0,
            lng: e.value['position']?.longitude ?? 0,
            type: e.value['type'],
          )).toList(),
        );

        final result = await repository.estimateFare(request);
        setState(() {
          _apiFare = result.finalFare;
          _isEstimating = false;
        });
      } catch (e) {
        setState(() => _isEstimating = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Estimation failed: $e')),
          );
        }
      }
    } else {
      setState(() => _totalDistance = 0.0);
    }
  }

  Future<void> _pickLocation(int index) async {
    // 1. Launch Search Screen
    final result = await context.push<Map<String, dynamic>>('/search');

    // 2. Handle Result
    if (result != null) {
      setState(() {
        _stops[index]['address'] = result['address'];
        _stops[index]['position'] = LatLng(result['lat'], result['lng']);
      });
      
      // 3. Recalculate Logic
      _calculateTotalDistance();
      _updateMapCamera();
    }
  }

  void _addStop() {
    setState(() {
      _stops.add({'address': 'Select Location', 'type': 'dropoff', 'position': null});
    });
  }

  void _removeStop(int index) {
    if (_stops.length > 2) {
      setState(() {
        _stops.removeAt(index);
      });
      _calculateTotalDistance();
      _updateMapCamera();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum 2 stops required')),
      );
    }
  }

  void _updateMapCamera() {
    if (_mapController == null) return;
    
    final positions = _stops
        .where((s) => s['position'] != null)
        .map((s) => s['position'] as LatLng)
        .toList();

    if (positions.isEmpty) return;

    if (positions.length == 1) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(positions[0], 15));
      return;
    }

    // Calculate bounds with padding
    double minLat = positions[0].latitude;
    double maxLat = positions[0].latitude;
    double minLng = positions[0].longitude;
    double maxLng = positions[0].longitude;

    for (final pos in positions) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100, // Increased padding
      ),
    );
  }

  double get _totalFare {
    // Pricing logic: Base £5.00 + £1.50 per mile + £3.00 per extra stop
    // _totalDistance is in km, convert to miles (1 km = 0.621371 miles)
    double miles = _totalDistance * 0.621371;
    double stopCharge = (_stops.length - 2) * 3.00;
    if (stopCharge < 0) stopCharge = 0;
    
    return 5.00 + (miles * 1.50) + stopCharge;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        title: Text('Multi-Stop Delivery', style: GoogleFonts.outfit(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isEstimating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        child: Column(
          children: [
            // Route Map Preview (Fully Functional)
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                ],
              ),
              child: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _getUserLocation(); // Center on user
                    },
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(51.5074, -0.1278), // Default London
                      zoom: 13,
                    ),
                    markers: _stops
                        .asMap()
                        .entries
                        .where((e) => e.value['position'] != null)
                        .map((e) => Marker(
                              markerId: MarkerId('stop_${e.key}'),
                              position: e.value['position'] as LatLng,
                              infoWindow: InfoWindow(title: e.key == 0 ? 'Pickup' : 'Stop ${e.key}'),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                e.key == 0 ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed,
                              ),
                            ))
                        .toSet(),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                  Positioned(
                    bottom: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, color: AppTheme.successGreen, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Route Optimized',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successGreen,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
  
            // Stops List
            ReorderableListView.builder(
              padding: const EdgeInsets.all(20),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stops.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = _stops.removeAt(oldIndex);
                  _stops.insert(newIndex, item);
                  _calculateTotalDistance();
                  _updateMapCamera();
                });
              },
              itemBuilder: (context, index) {
                final stop = _stops[index];
                final isPickup = index == 0;
                final isFilled = stop['position'] != null;
                
                return Container(
                  key: ValueKey(stop),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFilled ? AppTheme.primaryBlue : Colors.grey[300]!,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _pickLocation(index),
                    leading: Icon(
                      isPickup ? Icons.my_location_rounded : Icons.location_on_outlined, 
                      color: isPickup ? AppTheme.primaryBlue : Colors.redAccent
                    ),
                    title: Flexible(
                      child: Text(
                        isFilled ? (stop['address'] as String) : (isPickup ? 'Enter Pickup' : 'Enter Destination'),
                        style: GoogleFonts.outfit(
                          fontWeight: isFilled ? FontWeight.bold : FontWeight.normal,
                          color: isFilled ? AppTheme.textPrimary : Colors.grey[500],
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    subtitle: isFilled ? Text(
                      isPickup ? 'Pickup Point' : 'Stop $index',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (index > 0)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                            onPressed: () => _removeStop(index),
                          ),
                        const Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isEstimating || _isCreating ? null : _addStop,
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Add Stop'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: AppTheme.primaryBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pricing & Checkout
          Container(
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${(_totalDistance * 0.621371).toStringAsFixed(1)} miles • ${_stops.length} location(s)',
                          style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _isEstimating ? 'Calculating...' : '${ref.read(authProvider).currencySymbol}${_apiFare.toStringAsFixed(2)}',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: (_totalDistance > 0 && !_isEstimating && !_isCreating)
                          ? () async {
                              setState(() => _isCreating = true);
                              try {
                                final repository = ref.read(deliveryRepositoryProvider);
                                final pickup = _stops.first;
                                final dropoff = _stops.last;
                                
                                final request = DeliveryRequest(
                                  pickupAddress: pickup['address'],
                                  pickupLat: pickup['position'].latitude,
                                  pickupLng: pickup['position'].longitude,
                                  dropoffAddress: dropoff['address'],
                                  dropoffLat: dropoff['position'].latitude,
                                  dropoffLng: dropoff['position'].longitude,
                                  vehicleType: 'Van',
                                  serviceTier: 'Standard',
                                  fare: _apiFare,
                                  description: 'Multi-stop delivery with ${_stops.length} locations',
                                  stops: _stops.asMap().entries.map((e) => DeliveryStopModel(
                                    address: e.value['address'],
                                    lat: e.value['position']?.latitude ?? 0,
                                    lng: e.value['position']?.longitude ?? 0,
                                    type: e.value['type'],
                                  )).toList(),
                                );

                                await repository.createDelivery(request);
                                setState(() => _isCreating = false);
                                if (mounted) {
                                  context.push('/wallet'); // Go to payment
                                }
                              } catch (e) {
                                setState(() => _isCreating = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Order failed: $e')),
                                  );
                                }
                              }
                          }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 5,
                        shadowColor: AppTheme.primaryBlue.withOpacity(0.4),
                      ),
                      child: _isCreating 
                        ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            'Confirm',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
}
}
