import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/api_client.dart';

class BulkShippingScreen extends ConsumerStatefulWidget {
  const BulkShippingScreen({super.key});

  @override
  ConsumerState<BulkShippingScreen> createState() => _BulkShippingScreenState();
}

class _BulkShippingScreenState extends ConsumerState<BulkShippingScreen> {
  final List<Map<String, dynamic>> _shipments = [
    {'pickup': TextEditingController(), 'delivery': TextEditingController(), 'weight': '1.0', 'type': 'Parcel'},
  ];
  bool _isSubmitting = false;

  void _addShipment() {
    if (_shipments.length < 5) {
      setState(() {
        _shipments.add({'pickup': TextEditingController(), 'delivery': TextEditingController(), 'weight': '1.0', 'type': 'Parcel'});
      });
    }
  }

  void _removeShipment(int index) {
    if (_shipments.length > 1) {
      setState(() {
        _shipments.removeAt(index);
      });
    }
  }

  Future<void> _submitBatch() async {
    setState(() => _isSubmitting = true);
    try {
      final items = _shipments.map((s) => {
        'pickup_address': s['pickup'].text,
        'delivery_address': s['delivery'].text,
        'package_type': s['type'],
        'weight': double.tryParse(s['weight']) ?? 1.0,
        'estimated_fare': 15.0, // Mock fare for demo
      }).toList();

      final api = ref.read(apiClientProvider);
      await api.dio.post('business/bulk-book', data: {'deliveries': items});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bulk booking successful!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Bulk Shipping', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitBatch,
            child: _isSubmitting 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('SUBMIT', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryBlue)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _shipments.length,
        itemBuilder: (context, index) => _ShipmentForm(
          index: index,
          shipment: _shipments[index],
          onRemove: () => _removeShipment(index),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addShipment,
        backgroundColor: Colors.black87,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Shipment', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _ShipmentForm extends StatelessWidget {
  final int index;
  final Map<String, dynamic> shipment;
  final VoidCallback onRemove;

  const _ShipmentForm({required this.index, required this.shipment, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SHIPMENT #${index + 1}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black26, fontSize: 12, letterSpacing: 1)),
              if (index > 0) IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20)),
            ],
          ),
          const SizedBox(height: 16),
          _field('Pickup Address', shipment['pickup'], Icons.location_on_outlined),
          const SizedBox(height: 16),
          _field('Delivery Address', shipment['delivery'], Icons.local_shipping_outlined),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Package Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: shipment['type'],
                      items: ['Parcel', 'Document', 'Pallet'].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (v) => shipment['type'] = v,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Weight (kg)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    TextField(
                      onChanged: (v) => shipment['weight'] = v,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '1.0'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
