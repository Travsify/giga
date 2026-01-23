import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class MultiStopScreen extends StatefulWidget {
  const MultiStopScreen({super.key});

  @override
  State<MultiStopScreen> createState() => _MultiStopScreenState();
}

class _MultiStopScreenState extends State<MultiStopScreen> {
  final List<Map<String, dynamic>> _stops = [
    {'address': '123 Oxford St, W1D 2HG', 'type': 'pickup'},
    {'address': '456 Regent St, W1B 5TA', 'type': 'dropoff'},
    {'address': '789 Bond St, W1S 1DP', 'type': 'dropoff'},
  ];

  void _addStop() {
    setState(() {
      _stops.add({'address': 'Select Location', 'type': 'dropoff'});
    });
  }

  void _removeStop(int index) {
    if (_stops.length > 2) {
      setState(() {
        _stops.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum 2 stops required')),
      );
    }
  }

  double get _totalFare {
    // Base fare £5.00 + £3.00 per additional stop
    // Discount applied in display logic
    return 5.00 + ((_stops.length - 1) * 3.00);
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
      ),
      body: Column(
        children: [
          // Route Map Preview (Placeholder)
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[200],
            child: Stack(
              children: [
                Center(
                  child: Icon(Icons.map, size: 64, color: Colors.grey[400]),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                      ],
                    ),
                    child: const Text('Route Optimized', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                  ),
                ),
              ],
            ),
          ),

          // Stops List
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _stops.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = _stops.removeAt(oldIndex);
                  _stops.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final stop = _stops[index];
                final isPickup = index == 0;
                
                return Container(
                  key: ValueKey(stop),
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Icon(Icons.drag_handle, color: Colors.grey[400]),
                    title: Row(
                      children: [
                        Icon(
                          isPickup ? Icons.my_location : Icons.location_on,
                          color: isPickup ? AppTheme.primaryBlue : AppTheme.primaryRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(stop['address'] as String, style: const TextStyle(fontWeight: FontWeight.w500))),
                      ],
                    ),
                    subtitle: Text(
                      isPickup ? 'Pickup Point' : 'Stop ${index}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    trailing: index > 0 
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => _removeStop(index),
                        )
                      : const SizedBox(width: 48), // Balance spacing
                  ),
                );
              },
            ),
          ),
          
          // Add Stop Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: _addStop,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Add Another Stop'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppTheme.primaryBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Total & Action
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
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
                          '${_stops.length} Stops • 2.4 miles',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '£${_totalFare.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                               decoration: BoxDecoration(
                                color: AppTheme.successGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Save 50%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Proceeding to confirmation...')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
