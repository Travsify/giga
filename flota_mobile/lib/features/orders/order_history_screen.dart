import 'package:flutter/material.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Your Orders', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryBlue,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveOrders(),
          _buildCompletedOrders(),
        ],
      ),
    );
  }

  Widget _buildActiveOrders() {
    // Mock Active Orders
    final orders = [
      {
        'id': 'DEL-8821',
        'status': 'In Transit',
        'from': 'Camden Town',
        'to': 'Soho Square',
        'eta': '14 mins',
      },
    ];

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text('No active orders', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return FadeInUp(
          child: GestureDetector(
            onTap: () => context.push('/tracking/enhanced/${order['id']}'),
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(
                         '#${order['id']}',
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                       ),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                         decoration: BoxDecoration(
                           color: AppTheme.primaryBlue.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(20),
                         ),
                         child: Text(
                           order['status']!,
                           style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                         ),
                       ),
                     ],
                   ),
                   const Divider(height: 20),
                   Row(
                     children: [
                       const Icon(Icons.my_location, size: 16, color: Colors.grey),
                       const SizedBox(width: 8),
                       Text(order['from']!, style: const TextStyle(fontSize: 14)),
                     ],
                   ),
                   const SizedBox(height: 8),
                    Row(
                     children: [
                       const Icon(Icons.location_on, size: 16, color: AppTheme.primaryBlue),
                       const SizedBox(width: 8),
                       Text(order['to']!, style: const TextStyle(fontSize: 14)),
                     ],
                   ),
                   const SizedBox(height: 12),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('ETA: ${order['eta']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                       const Text('Track Now >', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                     ],
                   )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedOrders() {
      // Mock Completed
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text('No past orders', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
  }
}
