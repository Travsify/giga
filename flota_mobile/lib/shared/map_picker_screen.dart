import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flota_mobile/core/location_service.dart';

class MapPickerScreen extends StatefulWidget {
  final String title;
  final LatLng? initialPosition;

  const MapPickerScreen({
    super.key,
    required this.title,
    this.initialPosition,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  String _selectedAddress = 'Select location on map';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    if (_selectedPosition != null) {
      _updateAddress(_selectedPosition!);
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      Position position = await LocationService.getCurrentLocation();
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPosition = latLng;
        _isLoading = false;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
      _updateAddress(latLng);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateAddress(LatLng position) async {
    final address = await LocationService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );
    setState(() => _selectedAddress = address);
  }

  void _onMapTap(LatLng position) {
    setState(() => _selectedPosition = position);
    _updateAddress(position);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition ?? const LatLng(51.5074, -0.1278), // London
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _selectedPosition != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedPosition!,
                    ),
                  }
                : {},
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedAddress,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selectedPosition == null
                              ? null
                              : () => Navigator.pop(context, {
                                    'position': _selectedPosition,
                                    'address': _selectedAddress,
                                  }),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Confirm Location'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
