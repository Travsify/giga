import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/shared/map_picker_screen.dart';
import 'package:flota_mobile/features/marketplace/data/models/delivery_models.dart';
import 'package:flota_mobile/features/marketplace/delivery_provider.dart';
import 'package:flota_mobile/features/profile/profile_provider.dart';


class DeliveryRequestScreen extends ConsumerStatefulWidget {
  const DeliveryRequestScreen({super.key});

  @override
  ConsumerState<DeliveryRequestScreen> createState() => _DeliveryRequestScreenState();
}

class _DeliveryRequestScreenState extends ConsumerState<DeliveryRequestScreen> {
  String selectedVehicle = 'Bike';
  String selectedTier = 'Standard';
  
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
          serviceTier: selectedTier,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryProvider);
    final profileState = ref.watch(profileProvider);


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
                    AppTheme.primaryBlue.withOpacity(0.1),
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
                                  color: Colors.black.withOpacity(0.04),
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

                        // Saved Places Quick Select
                        if (profileState.user != null && (profileState.user?['home_address'] != null || profileState.user?['work_address'] != null))
                          FadeInUp(
                            delay: const Duration(milliseconds: 150),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Row(
                                children: [
                                  if (profileState.user?['home_address'] != null)
                                    _SavedPlaceChip(
                                      label: 'Home',
                                      icon: Icons.home_rounded,
                                      onTap: () {
                                        setState(() {
                                          dropoffAddress = profileState.user?['home_address'];
                                          dropoffLatLng = const LatLng(51.5074, -0.1278); // London mock
                                        });
                                        _updateEstimation();
                                      },
                                    ),
                                  const SizedBox(width: 12),
                                  if (profileState.user?['work_address'] != null)
                                    _SavedPlaceChip(
                                      label: 'Work',
                                      icon: Icons.work_rounded,
                                      onTap: () {
                                        setState(() {
                                          dropoffAddress = profileState.user?['work_address'];
                                          dropoffLatLng = const LatLng(51.5007, -0.1246); // Westminster mock
                                        });
                                        _updateEstimation();
                                      },
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
                        
                        FadeInLeft(
                          delay: const Duration(milliseconds: 350),
                          child: Text(
                            "Service Tier",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _ServiceTierCard(
                          label: 'Standard',
                          subtitle: 'Standard delivery time (30-45 mins)',
                          isSelected: selectedTier == 'Standard',
                          icon: Icons.delivery_dining_rounded,
                          color: AppTheme.primaryBlue,
                          onTap: () {
                            setState(() => selectedTier = 'Standard');
                            _updateEstimation();
                          },
                        ),
                        _ServiceTierCard(
                          label: 'Priority',
                          subtitle: 'Fastest delivery. Direct rider (15-25 mins)',
                          isSelected: selectedTier == 'Priority',
                          icon: Icons.bolt_rounded,
                          color: Colors.orange,
                          onTap: () {
                            setState(() => selectedTier = 'Priority');
                            _updateEstimation();
                          },
                        ),
                        _ServiceTierCard(
                          label: 'Saver',
                          subtitle: 'Eco-friendly. Flexible windows (60+ mins)',
                          isSelected: selectedTier == 'Saver',
                          icon: Icons.eco_rounded,
                          color: Colors.green,
                          onTap: () {
                            setState(() => selectedTier = 'Saver');
                            _updateEstimation();
                          },
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
                                      deliveryState.estimation != null 
                                        ? '£${deliveryState.estimation!.finalFare.toStringAsFixed(2)}'
                                        : '£0.00',
                                      style: GoogleFonts.outfit(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  if (deliveryState.estimation != null && deliveryState.estimation!.discount > 0)
                                    FadeIn(
                                      child: Text(
                                        'Giga+ Discount applied',
                                        style: TextStyle(color: AppTheme.successGreen, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: (pickupLatLng != null && dropoffLatLng != null && deliveryState.estimation != null)
                                  ? () {
                                      final req = DeliveryRequest(
                                        pickupAddress: pickupAddress!,
                                        pickupLat: pickupLatLng!.latitude,
                                        pickupLng: pickupLatLng!.longitude,
                                        dropoffAddress: dropoffAddress!,
                                        dropoffLat: dropoffLatLng!.latitude,
                                        dropoffLng: dropoffLatLng!.longitude,
                                        vehicleType: selectedVehicle,
                                        serviceTier: selectedTier,
                                        fare: deliveryState.estimation!.finalFare,
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
class _SavedPlaceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SavedPlaceChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppTheme.primaryBlue),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.2)),
      ),
    );
  }
}

class _ServiceTierCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceTierCard({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.black.withOpacity(0.05),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
