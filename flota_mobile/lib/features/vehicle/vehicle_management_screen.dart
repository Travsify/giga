import 'package:flota_mobile/features/profile/profile_provider.dart';
import 'package:flota_mobile/features/vehicle/add_vehicle_screen.dart';
import 'package:flota_mobile/features/vehicle/vehicle_model.dart';
import 'package:flota_mobile/features/vehicle/vehicle_service.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleManagementScreen extends ConsumerWidget {
  const VehicleManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final userState = ref.watch(profileProvider);
    final activeVehicleId = userState.user?['rider']?['active_vehicle_id'];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Manage Vehicles', style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: vehiclesAsync.when(
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return Center(
              child: Text(
                'No vehicles added yet.',
                style: GoogleFonts.outfit(color: Colors.white70),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              final isActive = vehicle.id == activeVehicleId;

              return Card(
                color: isActive ? AppTheme.primaryBlue.withOpacity(0.1) : AppTheme.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isActive ? const BorderSide(color: AppTheme.primaryBlue) : BorderSide.none,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    isActive ? Icons.check_circle : Icons.directions_car,
                    color: isActive ? AppTheme.primaryBlue : Colors.white70,
                    size: 32,
                  ),
                  title: Text(
                    "${vehicle.make ?? 'Unknown'} ${vehicle.model ?? ''} - ${vehicle.vehicleType.toUpperCase()}",
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.vehiclePlateNumber,
                        style: GoogleFonts.outfit(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            vehicle.isVerified ? Icons.verified : Icons.pending,
                            size: 14,
                            color: vehicle.isVerified ? Colors.greenAccent : Colors.orangeAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vehicle.isVerified ? 'Verified' : 'Pending Verification',
                            style: GoogleFonts.outfit(
                              color: vehicle.isVerified ? Colors.greenAccent : Colors.orangeAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: isActive
                      ? const Chip(
                          label: Text('ACTIVE'),
                          backgroundColor: AppTheme.primaryBlue,
                          labelStyle: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        )
                      : PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onSelected: (value) async {
                            if (value == 'activate') {
                              await _activateVehicle(context, ref, vehicle.id);
                            } else if (value == 'delete') {
                              await _deleteVehicle(context, ref, vehicle.id);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'activate',
                              child: Text('Set as Active'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                  onTap: () {
                     if (!isActive) _activateVehicle(context, ref, vehicle.id);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
          );
        },
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add),
        label: const Text("Add Vehicle"),
      ),
    );
  }

  Future<void> _activateVehicle(BuildContext context, WidgetRef ref, int vehicleId) async {
    try {
      await ref.read(vehicleServiceProvider).activateVehicle(vehicleId);
      ref.refresh(profileProvider.notifier).refresh(); // Update active status in profile
      ref.refresh(vehiclesProvider); // Refresh list to update UI
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle Activated!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to activate: $e')));
    }
  }

  Future<void> _deleteVehicle(BuildContext context, WidgetRef ref, int vehicleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle?'),
        content: const Text('Are you sure you want to delete this vehicle? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
       try {
        await ref.read(vehicleServiceProvider).deleteVehicle(vehicleId);
        ref.refresh(vehiclesProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle Deleted')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }
}
