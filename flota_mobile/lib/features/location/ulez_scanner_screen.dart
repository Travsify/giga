import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flota_mobile/features/location/ulez_service.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:animate_do/animate_do.dart';

class ULEZScannerScreen extends StatefulWidget {
  const ULEZScannerScreen({super.key});

  @override
  State<ULEZScannerScreen> createState() => _ULEZScannerScreenState();
}

class _ULEZScannerScreenState extends State<ULEZScannerScreen> {
  // Mock London Location
  final LatLng _initialPos = const LatLng(51.5074, -0.1278);
  bool _isLoading = false;
  bool? _isInZone;
  double _charge = 0.0;

  Future<void> _checkLocation() async {
    setState(() => _isLoading = true);
    final inZone = await ULEZService.isAddressInULEZ(_initialPos);
    final charge = ULEZService.calculateCharge(isElectric: false); // Assume non-electric for demo
    
    setState(() {
      _isLoading = false;
      _isInZone = inZone;
      _charge = charge;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ULEZ Scanner', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
             FadeInDown(
               child: Container(
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(
                   color: Colors.blue.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: Colors.blue.withOpacity(0.3)),
                 ),
                 child: Row(
                   children: [
                     const Icon(Icons.info_outline, color: Colors.blue),
                     const SizedBox(width: 15),
                     const Expanded(
                       child: Text(
                         'Check if your destination is within the Ultra Low Emission Zone.',
                         style: TextStyle(color: Colors.blueAccent),
                       ),
                     ),
                   ],
                 ),
               ),
             ),
             const SizedBox(height: 30),
             // Mock Map Area
             Container(
               height: 200,
               width: double.infinity,
               decoration: BoxDecoration(
                 color: Colors.grey[200],
                 borderRadius: BorderRadius.circular(16),
                 image: const DecorationImage(
                   image: NetworkImage('https://maps.googleapis.com/maps/api/staticmap?center=51.507, -0.127&zoom=12&size=600x300&key=YOUR_API_KEY'), // Placeholder logic or mock
                   fit: BoxFit.cover,
                 ),
               ),
               alignment: Alignment.center,
               child: _isLoading 
                   ? const CircularProgressIndicator()
                   : const Icon(Icons.location_on, size: 50, color: Colors.red),
             ),
             const SizedBox(height: 30),
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: _checkLocation,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppTheme.primaryBlue,
                   padding: const EdgeInsets.all(16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 ),
                 child: const Text('Check Current Location'),
               ),
             ),
             if (_isInZone != null) ...[
               const SizedBox(height: 30),
               FadeInUp(
                 child: Container(
                   padding: const EdgeInsets.all(20),
                   decoration: BoxDecoration(
                     color: _isInZone! ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(16),
                     border: Border.all(color: _isInZone! ? Colors.orange : Colors.green),
                   ),
                   child: Column(
                     children: [
                       Icon(
                         _isInZone! ? Icons.warning_amber_rounded : Icons.check_circle_outline, 
                         color: _isInZone! ? Colors.orange : Colors.green,
                         size: 48,
                       ),
                       const SizedBox(height: 10),
                       Text(
                         _isInZone! ? 'You are in the ULEZ Zone' : 'Outside ULEZ Zone',
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                       ),
                       const SizedBox(height: 5),
                       if (_isInZone!)
                         Text(
                           'Daily Charge: £${_charge.toStringAsFixed(2)}',
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.red),
                         ),
                       if (!_isInZone!)
                         const Text('No charge applied.', style: TextStyle(color: Colors.green)),
                     ],
                   ),
                 ),
               ),
             ],
          ],
        ),
      ),
    );
  }
}
