import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/shared/map_picker_screen.dart';
import 'package:flota_mobile/features/marketplace/delivery_provider.dart';
import 'package:flota_mobile/features/marketplace/data/models/delivery_models.dart';

class DeliveryRequestScreen extends ConsumerStatefulWidget {
  const DeliveryRequestScreen({super.key});

  @override
  ConsumerState<DeliveryRequestScreen> createState() => _DeliveryRequestScreenState();
}

class _DeliveryRequestScreenState extends ConsumerState<DeliveryRequestScreen> {
  String selectedVehicle = 'Bike';
  
  String? pickupAddress;
  LatLng? pickupLatLng;
  
  String? dropoffAddress;
  LatLng? dropoffLatLng;

  void _pickLocation(bool isPickup) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          title: isPickup ? 'Select Pickup' : 'Select Drop-off',
          initialPosition: isPickup ? pickupLatLng : dropoffLatLng,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (isPickup) {
          pickupAddress = result['address'];
          pickupLatLng = result['position'];
        } else {
          dropoffAddress = result['address'];
          dropoffLatLng = result['position'];
        }
      });
      _updateEstimation();
    }
  }

  void _updateEstimation() {
    if (pickupLatLng != null && dropoffLatLng != null) {
      ref.read(deliveryProvider.notifier).estimateFare(
        DeliveryEstimationRequest(
          pickupLat: pickupLatLng!.latitude,
          pickupLng: pickupLatLng!.longitude,
          dropoffLat: dropoffLatLng!.latitude,
          dropoffLng: dropoffLatLng!.longitude,
          vehicleType: selectedVehicle,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Decor (Consistent with Auth)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
                      ),
                      Text(
                        'Book Delivery',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInDown(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            "Where are we moving?",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Location Selection Card
                        FadeInUp(
                          delay: const Duration(milliseconds: 100),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                              border: Border.all(color: Colors.black.withOpacity(0.05)),
                            ),
                            child: Column(
                              children: [
                                _LocationItem(
                                  label: 'Pickup Location',
                                  address: pickupAddress ?? 'Tap to select pickup point',
                                  icon: Icons.circle_outlined,
                                  iconColor: AppTheme.primaryBlue,
                                  onTap: () => _pickLocation(true),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Container(
                                    height: 30,
                                    width: 1,
                                    color: Colors.black12,
                                  ),
                                ),
                                _LocationItem(
                                  label: 'Drop-off Location',
                                  address: dropoffAddress ?? 'Tap to select destination',
                                  icon: Icons.location_on_rounded,
                                  iconColor: AppTheme.primaryRed,
                                  onTap: () => _pickLocation(false),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                        
                        FadeInLeft(
                          delay: const Duration(milliseconds: 200),
                          child: Text(
                            "Select Vehicle",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Vehicle Selection
                        FadeInUp(
                          delay: const Duration(milliseconds: 300),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _VehicleTypeCard(
                                  label: 'Bike',
                                  isSelected: selectedVehicle == 'Bike',
                                  icon: Icons.motorcycle_rounded,
                                  onTap: () {
                                    setState(() => selectedVehicle = 'Bike');
                                    _updateEstimation();
                                  },
                                ),
                                const SizedBox(width: 12),
                                _VehicleTypeCard(
                                  label: 'Van',
                                  isSelected: selectedVehicle == 'Van',
                                  icon: Icons.local_shipping_rounded,
                                  onTap: () {
                                    setState(() => selectedVehicle = 'Van');
                                    _updateEstimation();
                                  },
                                ),
                                const SizedBox(width: 12),
                                _VehicleTypeCard(
                                  label: 'Truck',
                                  isSelected: selectedVehicle == 'Truck',
                                  icon: Icons.fire_truck_rounded,
                                  onTap: () {
                                    setState(() => selectedVehicle = 'Truck');
                                    _updateEstimation();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // Bottom Fare Section
                FadeInUp(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated Fare',
                                  style: GoogleFonts.outfit(
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (deliveryState.isLoading)
                                  const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else
                                  Text(
                                    deliveryState.estimatedFare != null 
                                      ? '£${deliveryState.estimatedFare!.toStringAsFixed(2)}'
                                      : '£0.00',
                                    style: GoogleFonts.outfit(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: (pickupLatLng != null && dropoffLatLng != null && deliveryState.estimatedFare != null)
                                ? () {
                                    final req = DeliveryRequest(
                                      pickupAddress: pickupAddress!,
                                      pickupLat: pickupLatLng!.latitude,
                                      pickupLng: pickupLatLng!.longitude,
                                      dropoffAddress: dropoffAddress!,
                                      dropoffLat: dropoffLatLng!.latitude,
                                      dropoffLng: dropoffLatLng!.longitude,
                                      vehicleType: selectedVehicle,
                                      fare: deliveryState.estimatedFare!,
                                    );
                                    context.push('/checkout', extra: req);
                                  }
                                : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              child: Text(
                                'Book Now',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
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
          ),
        ],
      ),
    );
  }
}

class _LocationItem extends StatelessWidget {
  final String label;
  final String address;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _LocationItem({
    required this.label,
    required this.address,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    address,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

class _VehicleTypeCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _VehicleTypeCard({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.black.withOpacity(0.05),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ] : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.primaryBlue,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
