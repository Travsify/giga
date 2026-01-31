import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flota_mobile/shared/map_picker_screen.dart';
import 'package:flota_mobile/core/error_handler.dart';
import 'package:flota_mobile/features/marketplace/data/delivery_repository.dart';
import 'package:flota_mobile/features/marketplace/data/models/delivery_models.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:go_router/go_router.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  String _pickupAddress = '';
  String _dropoffAddress = '';
  String? _selectedService;
  double _estimatedFare = 0.0;
  bool _isEstimating = false;
  bool _isBooking = false;

  Future<void> _selectLocation(bool isPickup) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapPickerScreen(
            title: isPickup ? 'Select Pickup Location' : 'Select Drop-off Location',
            initialPosition: isPickup ? _pickupLocation : _dropoffLocation,
          ),
        ),
      );

      if (result != null) {
        setState(() {
          if (isPickup) {
            _pickupLocation = result['position'];
            _pickupAddress = result['address'];
          } else {
            _dropoffLocation = result['position'];
            _dropoffAddress = result['address'];
          }
        });

        if (_pickupLocation != null && _dropoffLocation != null && _selectedService != null) {
          _estimateFare();
        }
      }
    } catch (e) {
      if (mounted) ErrorHandler.handleError(context, e);
    }
  }

  Future<void> _estimateFare() async {
     if (_pickupLocation == null || _dropoffLocation == null || _selectedService == null) return;
     
     setState(() => _isEstimating = true);
     
     try {
       final repository = ref.read(deliveryRepositoryProvider);
       final request = DeliveryEstimationRequest(
         pickupLat: _pickupLocation!.latitude,
         pickupLng: _pickupLocation!.longitude,
         dropoffLat: _dropoffLocation!.latitude,
         dropoffLng: _dropoffLocation!.longitude,
         vehicleType: _selectedService == 'bike' ? 'Bike' : 'Van',
         serviceTier: 'Standard',
         stops: [
           DeliveryStopModel(address: _pickupAddress, lat: _pickupLocation!.latitude, lng: _pickupLocation!.longitude, type: 'pickup'),
           DeliveryStopModel(address: _dropoffAddress, lat: _dropoffLocation!.latitude, lng: _dropoffLocation!.longitude, type: 'dropoff'),
         ],
       );

       final result = await repository.estimateFare(request);
       setState(() {
         _estimatedFare = result.finalFare;
         _isEstimating = false;
       });
     } catch (e) {
       setState(() => _isEstimating = false);
       if (mounted) ErrorHandler.handleError(context, e);
     }
  }

  Future<void> _confirmBooking() async {
    if (_pickupLocation == null || _dropoffLocation == null || _selectedService == null) {
      ErrorHandler.handleError(context, 'Please select all required fields');
      return;
    }

    setState(() => _isBooking = true);

    try {
      final repository = ref.read(deliveryRepositoryProvider);
      final request = DeliveryRequest(
        pickupAddress: _pickupAddress,
        pickupLat: _pickupLocation!.latitude,
        pickupLng: _pickupLocation!.longitude,
        dropoffAddress: _dropoffAddress,
        dropoffLat: _dropoffLocation!.latitude,
        dropoffLng: _dropoffLocation!.longitude,
        vehicleType: _selectedService == 'bike' ? 'Bike' : 'Van',
        serviceTier: 'Standard',
        fare: _estimatedFare,
        parcelCategory: 'General',
        parcelSize: 'Medium',
        description: 'Single parcel delivery via ${_selectedService == 'bike' ? 'Bike' : 'Van'}',
      );

      await repository.createDelivery(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Booking created successfully!')),
        );
        context.push('/wallet'); // Redirect to payment
      }
    } catch (e) {
      if (mounted) ErrorHandler.handleError(context, e);
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where to?',
                style: theme.textTheme.displayLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Select pickup and drop-off locations',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 30),
              _LocationInput(
                icon: Icons.circle_outlined,
                hint: _pickupAddress.isEmpty ? 'Pickup Location' : _pickupAddress,
                color: theme.primaryColor,
                onTap: () => _selectLocation(true),
              ),
              const SizedBox(height: 15),
              _LocationInput(
                icon: Icons.location_on_rounded,
                hint: _dropoffAddress.isEmpty ? 'Drop-off Location' : _dropoffAddress,
                color: Colors.redAccent,
                onTap: () => _selectLocation(false),
              ),
              const SizedBox(height: 40),
              Text(
                'Service Types',
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _ServiceCard(
                      title: 'Standard Bike',
                      price: _estimatedFare > 0 && _selectedService == 'bike'
                          ? '${ref.watch(authProvider).currencySymbol}${_estimatedFare.toStringAsFixed(2)}'
                          : 'Starting at ${ref.watch(authProvider).currencySymbol}3.00',
                      eta: _isEstimating && _selectedService == 'bike' ? 'Calculating...' : '5 mins away',
                      icon: Icons.motorcycle,
                      isSelected: _selectedService == 'bike',
                      onTap: () async {
                        setState(() => _selectedService = 'bike');
                        await _estimateFare();
                      },
                    ),
                    _ServiceCard(
                      title: 'Delivery Van',
                      price: _estimatedFare > 0 && _selectedService == 'van'
                          ? '${ref.watch(authProvider).currencySymbol}${_estimatedFare.toStringAsFixed(2)}'
                          : 'Starting at ${ref.watch(authProvider).currencySymbol}12.00',
                      eta: _isEstimating && _selectedService == 'van' ? 'Calculating...' : '12 mins away',
                      icon: Icons.local_shipping,
                      isSelected: _selectedService == 'van',
                      onTap: () async {
                        setState(() => _selectedService = 'van');
                        await _estimateFare();
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isBooking ? null : _confirmBooking,
                  child: _isBooking 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Booking'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationInput extends StatelessWidget {
  final IconData icon;
  final String hint;
  final Color color;
  final VoidCallback onTap;

  const _LocationInput({
    required this.icon,
    required this.hint,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                hint,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String price;
  final String eta;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.price,
    required this.eta,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withOpacity(0.05) : theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primaryColor, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
                  Text(eta, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
            Text(price, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}
