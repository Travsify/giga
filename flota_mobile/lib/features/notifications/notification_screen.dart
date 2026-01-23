import 'package:flutter/material.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Notifications
    final notifications = [
      {
        'title': 'Rider Arriving Soon',
        'body': 'Your eco-rider James is 5 mins away!',
        'time': '2 mins ago',
        'icon': Icons.pedal_bike_rounded,
        'color': AppTheme.successGreen,
      },
      {
        'title': 'Payment Successful',
        'body': 'Top-up of £20.00 was successful.',
        'time': '1 hour ago',
        'icon': Icons.account_balance_wallet_rounded,
        'color': AppTheme.primaryBlue,
      },
      {
        'title': 'New Login',
        'body': 'New login detected from London, UK.',
        'time': '1 day ago',
        'icon': Icons.security_rounded,
        'color': Colors.orange,
      },
      {
        'title': 'Welcome to Giga!',
        'body': 'Get started by creating your first shipment.',
        'time': '2 days ago',
        'icon': Icons.waving_hand_rounded,
        'color': Colors.purple,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: AppTheme.primaryBlue),
            onPressed: () {}, // Todo: Mark all read
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 30),
        itemBuilder: (context, index) {
          final item = notifications[index];
          return FadeInUp(
            delay: Duration(milliseconds: index * 100),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item['icon'] as IconData, color: item['color'] as Color),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            item['time'] as String,
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item['body'] as String,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
