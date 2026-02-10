import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

class ShopAndShipScreen extends ConsumerStatefulWidget {
  const ShopAndShipScreen({super.key});

  @override
  ConsumerState<ShopAndShipScreen> createState() => _ShopAndShipScreenState();
}

class _ShopAndShipScreenState extends ConsumerState<ShopAndShipScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _addresses;
  List<dynamic> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Mocking API calls for now based on the backend controller found
      // In a real scenario, we'd use a dedicated repository
      
      // Addresses
      _addresses = {
        'uk_address': {
          'line_1': 'Giga Logistics Hub, Unit 5',
          'line_2': 'Industrial Park (GIGA-USER-123)',
          'city': 'London',
          'postcode': 'E1 6AN',
          'country': 'United Kingdom',
        },
        'us_address': {
          'line_1': '123 Giga Way',
          'line_2': 'Suite 400 (GIGA-USER-123)',
          'city': 'Houston',
          'state': 'TX',
          'postcode': '77002',
          'country': 'USA',
        }
      };

      // Packages
      _packages = [
        {
          'id': 1,
          'origin': 'London, UK',
          'status': 'at_hub',
          'description': 'Electronics',
          'tracking_no': 'GIGA-UK-7721',
          'date': '2 days ago',
        },
        {
          'id': 2,
          'origin': 'Houston, USA',
          'status': 'in_transit',
          'description': 'Clothing',
          'tracking_no': 'GIGA-US-4412',
          'date': '5 days ago',
        }
      ];

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Ship & Shop', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentCyan,
          labelColor: AppTheme.accentCyan,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Hub Addresses'),
            Tab(text: 'My Packages'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildAddressesTab(),
              _buildPackagesTab(),
            ],
          ),
    );
  }

  Widget _buildAddressesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            child: Text(
              "Your Global Proxy Addresses",
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Shop from any UK or US store and use these addresses at checkout. We'll handle the rest!",
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 32),
          _buildAddressCard('United Kingdom', Icons.euro_symbol, _addresses?['uk_address']),
          const SizedBox(height: 24),
          _buildAddressCard('United States', Icons.attach_money, _addresses?['us_address']),
        ],
      ),
    );
  }

  Widget _buildAddressCard(String country, IconData icon, Map<String, dynamic>? addr) {
    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.accentCyan, size: 24),
                const SizedBox(width: 12),
                Text(country, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    // Copy all logic
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy All'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.accentCyan),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),
            _buildAddressLine('Line 1', addr?['line_1']),
            _buildAddressLine('Line 2', addr?['line_2']),
            _buildAddressLine('City', addr?['city']),
            if (addr?['state'] != null) _buildAddressLine('State', addr?['state']),
            _buildAddressLine('Postcode', addr?['postcode']),
            _buildAddressLine('Country', addr?['country']),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressLine(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value ?? '-', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPackagesTab() {
    if (_packages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[800]),
            const SizedBox(height: 16),
            Text("No packages yet", style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _packages.length,
      itemBuilder: (context, index) {
        final pkg = _packages[index];
        return FadeInUp(
          delay: Duration(milliseconds: index * 100),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping_outlined, color: AppTheme.accentCyan),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pkg['description'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("From: ${pkg['origin']} • ${pkg['date']}", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(pkg['tracking_no'], style: const TextStyle(color: AppTheme.accentCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pkg['status'] == 'at_hub' ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    pkg['status'] == 'at_hub' ? 'At Hub' : 'In Transit',
                    style: TextStyle(
                      color: pkg['status'] == 'at_hub' ? Colors.orange : Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
