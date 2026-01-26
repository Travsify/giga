import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/features/business/business_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';

class BulkBookingScreen extends ConsumerStatefulWidget {
  const BulkBookingScreen({super.key});

  @override
  ConsumerState<BulkBookingScreen> createState() => _BulkBookingScreenState();
}

class _BulkBookingScreenState extends ConsumerState<BulkBookingScreen> {
  final List<Map<String, dynamic>> _draftBatch = [];
  bool _isProcessing = false;

  void _addMockItem() {
    setState(() {
      _draftBatch.add({
        'pickup_address': 'Central London Warehouse',
        'dropoff_address': 'Downing Street, London',
        'parcel_type': 'Box',
        'fare': 12.50,
      });
    });
  }

  Future<void> _submitBatch() async {
    if (_draftBatch.isEmpty) return;

    setState(() => _isProcessing = true);
    final success = await ref.read(businessProvider.notifier).bulkBook(_draftBatch);
    setState(() => _isProcessing = false);

    if (success) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: Text('${_draftBatch.length} deliveries have been booked successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        final error = ref.read(businessProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to process batch')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bulk Booking', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildInfoBanner(),
          Expanded(
            child: _draftBatch.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _draftBatch.length,
                    itemBuilder: (context, index) => _buildBatchItem(index),
                  ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryBlue.withOpacity(0.05),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Upload CSV or use our B2B portal for large batches. Here you can review and confirm smaller batches.',
              style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No items in batch',
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addMockItem,
            icon: const Icon(Icons.add),
            label: const Text('Add Demo Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchItem(int index) {
    final item = _draftBatch[index];
    return FadeInLeft(
      duration: Duration(milliseconds: 200 + (index * 50)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Delivery #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('£${item['fare']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              ],
            ),
            const Divider(height: 24),
            _rowInfo(Icons.location_on_outlined, item['pickup_address']),
            const SizedBox(height: 8),
            _rowInfo(Icons.flag_outlined, item['dropoff_address']),
            const SizedBox(height: 8),
            Row(
              children: [
                _chip(item['parcel_type']),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => setState(() => _draftBatch.removeAt(index)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[800]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBottomBar() {
    if (_draftBatch.isEmpty) return const SizedBox.shrink();

    final total = _draftBatch.fold<double>(0, (sum, item) => sum + (double.tryParse(item['fare'].toString()) ?? 0.0));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Batch Cost', style: GoogleFonts.outfit(fontSize: 16)),
                Text('£${total.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _submitBatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm & Book Batch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _addMockItem,
              child: const Text('Add Another Item'),
            ),
          ],
        ),
      ),
    );
  }
}
