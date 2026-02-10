import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:flota_mobile/features/marketplace/weather_service.dart';
import 'package:flota_mobile/features/marketplace/home_widgets.dart';
import 'package:flota_mobile/features/sustainability/carbon_dashboard_screen.dart';
import 'package:flota_mobile/features/location/ulez_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flota_mobile/features/wallet/bill_payment_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic> _weather = {
    'temp': '--',
    'condition': 'Loading',
    'icon': Icons.cloud,
    'location': 'London',
  };

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final data = await WeatherService.getCurrentWeather();
    if (mounted) setState(() => _weather = data);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    // Stream for wallet balance
    final userStream = FirebaseFirestore.instance.collection('users').doc(authState.userId).snapshots();

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
                    colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
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
                                Icon(_weather['icon'], color: Colors.white70, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '${_weather['temp']}, ${_weather['condition']} in ${_weather['location']}',
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
                            _UlezStatusBubble(),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.push('/profile'),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_outline, color: Colors.white, size: 28),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.push('/notifications'),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.2),
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
                              color: theme.cardTheme.color?.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
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
                                      '${ref.watch(authProvider).currencySymbol}${balance.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (authState.isNigeria)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.verified_user_rounded, color: Colors.white, size: 12),
                                            SizedBox(width: 4),
                                            Text(
                                              'Secured by Insta-Escrow',
                                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () => context.push('/wallet'), // Redirect to wallet
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor: Colors.white,
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
                child: GestureDetector(
                  onTap: () => context.push('/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
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
          ),

          // Giga-Bid Live Monitor (Nigeria Only)
          if (authState.isNigeria)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: FadeInUp(
                  delay: const Duration(milliseconds: 250),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D25),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
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
                                  'Giga-Bid Live Monitor',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Real-time delivery auctions',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                               decoration: BoxDecoration(
                                 color: theme.primaryColor.withOpacity(0.2),
                                 borderRadius: BorderRadius.circular(10),
                               ),
                               child: const Text(
                                 'ACTIVE',
                                 style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                               ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'No active bids at the moment. Start a new shipment to see bidding in action!',
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Logistics Banners Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Picks for You',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  // Business Logistics Banner
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: buildDiscountBanner(
                      context: context,
                      icon: Icons.business_center_rounded,
                      title: 'Giga for Business',
                      subtitle: authState.role == 'Business' ? 'Manage your corporate account' : (authState.isUK ? 'Bulk shipping for UK sellers' : 'Scale your logistics across Nigeria'),
                      colors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
                      onTap: () => context.push(authState.role == 'Business' ? '/business-dashboard' : '/business-enrollment'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // NHS Discount Banner (UK Only)
                  if (authState.isUK)
                    FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: buildDiscountBanner(
                          context: context,
                          icon: Icons.local_hospital_rounded,
                          title: 'NHS & Service Heroes',
                          subtitle: 'Free delivery for NHS workers',
                          colors: [AppTheme.primaryBlue, AppTheme.accentCyan],
                          onTap: () async {
                            // ... existing NHS logic
                          },
                        ),
                      ),
                    ),
                  
                  // Send-to-Contact Banner (Nigeria Only)
                  if (authState.isNigeria)
                    FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: buildDiscountBanner(
                          context: context,
                          icon: Icons.contact_phone_rounded,
                          title: 'Send to Contact',
                          subtitle: 'No address? Just pick a contact',
                          colors: [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
                          onTap: () => context.push('/send-to-contact'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Main Logistics Hero Actions (Send & Track)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: FadeInLeft(
                      child: _HeroActionCard(
                        title: 'Send',
                        subtitle: 'Move anything now',
                        icon: Icons.local_shipping_outlined,
                        color: theme.colorScheme.secondary,
                        onTap: () => context.push('/delivery-request'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: FadeInRight(
                      child: _HeroActionCard(
                        title: 'Track',
                        subtitle: 'Live shipment status',
                        icon: Icons.location_searching_rounded,
                        color: theme.primaryColor,
                        onTap: () => context.push('/tracking/enhanced/123'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Secondary Logistics Services
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'More Services',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  const SizedBox(height: 15),
                  // Nigeria specific row
                  if (authState.isNigeria)
                    Row(
                      children: [
                        Expanded(
                          child: FadeInUp(
                            child: _ServiceTile(
                              title: 'Multi-Stop',
                              subtitle: 'Bulk drops',
                              icon: Icons.alt_route_rounded,
                              color: theme.primaryColor,
                              onTap: () => context.push('/multi-stop'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: FadeInUp(
                            child: _ServiceTile(
                              title: 'Bill Payments',
                              subtitle: 'Earn ₦50 Loyalty',
                              icon: Icons.receipt_long_rounded,
                              color: Colors.orange,
                              onTap: () => context.push('/bill-payment'),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // UK specific rows
                  if (authState.isUK) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _ServiceTile(
                            title: 'Giga Lockers',
                            subtitle: 'Secure pickup',
                            icon: Icons.inventory_2_outlined,
                            color: AppTheme.slateBlue,
                            onTap: () => context.push('/lockers'),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _ServiceTile(
                            title: 'ULEZ Check',
                            subtitle: 'UK Compliance',
                            icon: Icons.camera_alt_rounded,
                            color: AppTheme.successGreen,
                            onTap: () => context.push('/ulez'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _ServiceTile(
                            title: 'Retail Returns',
                            subtitle: 'Amazon & ASOS',
                            icon: Icons.assignment_return_rounded,
                            color: Colors.redAccent,
                            onTap: () => context.push('/returns'),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _ServiceTile(
                            title: 'Send a Gift',
                            subtitle: 'Wrap & ship',
                            icon: Icons.card_giftcard_rounded,
                            color: Colors.pinkAccent,
                            onTap: () => context.push('/gifts'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Common services
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _ServiceTile(
                          title: 'Scheduled',
                          subtitle: 'Book for later',
                          icon: Icons.calendar_month_rounded,
                          color: Colors.blueGrey,
                          onTap: () => context.push('/delivery-request?scheduled=true'),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _ServiceTile(
                          title: 'Ship & Shop',
                          subtitle: 'Global delivery',
                          icon: Icons.language_rounded,
                          color: Colors.deepPurple,
                          onTap: () => context.push('/ship-and-shop'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Sustainability Impact (UK Only)
          if (authState.isUK)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: FadeInUp(
                child: ref.watch(sustainabilityStatsProvider).when(
                  loading: () => Container(height: 100, color: Colors.grey[100]),
                  error: (err, stack) => const SizedBox.shrink(),
                  data: (stats) => Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.successGreen.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.eco_rounded, color: AppTheme.successGreen, size: 32),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Carbon Impact',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'You\'ve saved ${stats.totalCo2SavedKg.toStringAsFixed(1)}kg of CO2 this month.',
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/carbon'),
                          child: const Text('View Details'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Live Heatmap Widget
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: FadeInUp(
                delay: const Duration(milliseconds: 700),
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
                        onPressed: () => context.push('/promos'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: GestureDetector(
                      onTap: () => context.push('/giga-plus'),
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
                                    'Join GIGA+ for free deliveries & more',
                                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 150)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillPaymentScreen())),
        backgroundColor: AppTheme.accentCyan,
        icon: const Icon(Icons.receipt_long, color: Colors.white),
        label: const Text('Pay Bills', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.primaryColor.withOpacity(0.2), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            if (index == 1) context.push('/orders');
            if (index == 2) context.push('/wallet');
            if (index == 3) context.push('/profile');
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF0F1219),
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallet'),
            BottomNavigationBarItem(icon: Icon(Icons.person_pin_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _HeroActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeroActionCard({
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
        height: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
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
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
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
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UlezStatusBubble extends StatefulWidget {
  @override
  State<_UlezStatusBubble> createState() => _UlezStatusBubbleState();
}

class _UlezStatusBubbleState extends State<_UlezStatusBubble> {
  bool? _isInZone;

  @override
  void initState() {
    super.initState();
    _checkUlez();
  }

  Future<void> _checkUlez() async {
    // Mocking current location to Central London for ULEZ check
    final inZone = await ULEZService.isAddressInULEZ(const LatLng(51.5074, -0.1278));
    if (mounted) setState(() => _isInZone = inZone);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInZone == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isInZone! ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isInZone! ? Colors.orange : Colors.green, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isInZone! ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: Colors.white,
            size: 10,
          ),
          const SizedBox(width: 4),
          Text(
            _isInZone! ? 'ULEZ: Inside' : 'ULEZ: Clear',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


