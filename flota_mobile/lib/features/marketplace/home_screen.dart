import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';

import 'package:flota_mobile/features/marketplace/home_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    // Stream for wallet balance
    final userStream = FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Premium Header
          SliverToBoxAdapter(
            child: FadeInDown(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              authState.userName ?? 'User',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Weather Widget
                            Row(
                              children: [
                                const Icon(Icons.cloud_outlined, color: Colors.white70, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '12°C, Light Rain in London',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.push('/profile'),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_outline, color: Colors.white, size: 28),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Stack(
                                children: [
                                  const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Glassmorphic Wallet Card
                    StreamBuilder<DocumentSnapshot>(
                      stream: userStream,
                      builder: (context, snapshot) {
                        final balance = snapshot.data?.data() != null 
                            ? (snapshot.data!.get('wallet_balance') ?? 0.0) 
                            : 0.0;
                        
                        return ZoomIn(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Wallet Balance',
                                      style: TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '£${balance.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () => context.push('/checkout'), // Redirect to fund logic
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.primaryBlue,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Top Up'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search Bar Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppTheme.primaryBlue, size: 28),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          'Enter postcode (e.g., SW1A 1AA)',
                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Discount Banners Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Special Offers',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  // Student Discount Banner
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: buildDiscountBanner(
                      context: context,
                      icon: Icons.school_rounded,
                      title: 'Student Discount',
                      subtitle: '20% off with NUS Extra',
                      colors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Student verification coming soon!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // NHS Discount Banner
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: buildDiscountBanner(
                      context: context,
                      icon: Icons.local_hospital_rounded,
                      title: 'NHS Heroes',
                      subtitle: 'Free delivery for NHS workers',
                      colors: [AppTheme.primaryBlue, AppTheme.accentCyan],
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('NHS verification coming soon!')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Actions Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: FadeInLeft(
                          delay: const Duration(milliseconds: 300),
                          child: _ServiceTile(
                            title: 'Send Parcel',
                            subtitle: 'Express Delivery',
                            icon: Icons.unarchive_outlined,
                            color: const Color(0xFFFF4B2B),
                            onTap: () => context.push('/delivery-request'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: FadeInRight(
                          delay: const Duration(milliseconds: 400),
                          child: _ServiceTile(
                            title: 'Track',
                            subtitle: 'Real-time',
                            icon: Icons.location_on_rounded,
                            color: AppTheme.primaryBlue,
                            onTap: () => context.push('/tracking/enhanced/123'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: FadeInLeft(
                          delay: const Duration(milliseconds: 500),
                          child: _ServiceTile(
                            title: 'Eco Delivery',
                            subtitle: 'Carbon Neutral',
                            icon: Icons.pedal_bike_rounded,
                            color: AppTheme.successGreen,
                            onTap: () => context.push('/delivery-request'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: FadeInRight(
                          delay: const Duration(milliseconds: 600),
                          child: _ServiceTile(
                            title: 'Schedule',
                            subtitle: 'Choose Time',
                            icon: Icons.schedule_rounded,
                            color: AppTheme.accentCyan,
                            onTap: () => context.push('/multi-stop'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: FadeInLeft(
                          delay: const Duration(milliseconds: 700),
                          child: _ServiceTile(
                            title: 'Parcel Locker',
                            subtitle: 'Secure Pickup',
                            icon: Icons.inventory_2_outlined,
                            color: AppTheme.slateBlue,
                            onTap: () => context.push('/parcel-locker'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Live Heatmap Widget
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
              child: FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: const LiveHeatmapWidget(),
              ),
            ),
          ),

          // Promotion Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Promo & Highlights',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: Icon(Icons.stars_rounded, color: Colors.white.withOpacity(0.1), size: 150),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Giga Premium',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Get £10 off on first 3 deliveries',
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 2) context.push('/wallet');
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: Colors.grey[400],
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person_pin_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

