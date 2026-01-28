import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/api_client.dart';
import 'package:dio/dio.dart';

// Providers
final shopShipAddressProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ref.read(apiClientProvider).dio.get('/shop-and-ship/address');
  return response.data;
});

final shopShipPackagesProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await ref.read(apiClientProvider).dio.get('/shop-and-ship/packages');
  return response.data;
});

class ShopAndShipScreen extends ConsumerWidget {
  const ShopAndShipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shop & Ship'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My UK Address'),
              Tab(text: 'My Packages'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AddressTab(),
            _PackagesTab(),
          ],
        ),
      ),
    );
  }
}

class _AddressTab extends ConsumerWidget {
  const _AddressTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressAsync = ref.watch(shopShipAddressProvider);

    return addressAsync.when(
      data: (data) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Use this address when shopping online in the UK (Amazon, eBay, ASOS). We will receive it and ship to you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                   _RowItem('Unit', data['unit']),
                   const Divider(),
                   _RowItem('Street', data['street']),
                   const Divider(),
                   _RowItem('City', data['city']),
                   const Divider(),
                   _RowItem('Postcode', data['postcode']),
                   const Divider(),
                   const SizedBox(height: 10),
                   Container(
                     padding: const EdgeInsets.all(15),
                     decoration: BoxDecoration(
                       color: AppTheme.primaryRed.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(10),
                       border: Border.all(color: AppTheme.primaryRed)
                     ),
                     child: Column(
                       children: [
                         const Text('YOUR SUITE ID (MANDATORY)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
                         const SizedBox(height: 5),
                         Text(data['suite_number'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                       ],
                     ),
                   )
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy Full Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: data['full_address_text']));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied to clipboard!')));
              },
            )
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;
  const _RowItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class _PackagesTab extends ConsumerWidget {
  const _PackagesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(shopShipPackagesProvider);

    return packagesAsync.when(
      data: (packages) {
        if (packages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 10),
                Text('No packages received yet.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: packages.length,
          itemBuilder: (ctx, i) {
            final pkg = packages[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                  child: const Icon(Icons.shopping_bag, color: Colors.blue),
                ),
                title: Text(pkg['description'] ?? 'Package from UK'),
                subtitle: Text('Tracking: ${pkg['tracking_number']}\nWeight: ${pkg['weight_kg']}kg'),
                trailing: Chip(
                  label: Text(pkg['status'].toString().toUpperCase()),
                  backgroundColor: _getStatusColor(pkg['status']),
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading packages')),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'received': return Colors.orange;
      case 'paid': return Colors.blue;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      default: return Colors.grey;
    }
  }
}
