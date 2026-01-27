import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/features/profile/profile_provider.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:flota_mobile/core/payment_service.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';

class GigaPlusScreen extends ConsumerWidget {
  const GigaPlusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final isGigaPlus = profileState.subscription?['is_giga_plus'] ?? false;
    final authState = ref.watch(authProvider);
    final expiry = profileState.subscription?['expiry'];

    // Dynamic Pricing Logic
    String currency = '£';
    double price = 39.99;
    double freeDeliveryThreshold = 15.0;

    if (authState.countryCode == 'NG') {
      currency = '₦';
      price = 39.99 * 2025; // 1 GBP = 2025 NGN
      freeDeliveryThreshold = 15.0 * 2025;
    } else if (authState.countryCode == 'GH') {
      currency = '₵';
      price = 39.99 * 15; // Approximate rate, update if user provides
      freeDeliveryThreshold = 150.0;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppTheme.primaryBlue,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      ZoomIn(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_rounded, color: Colors.yellow, size: 60),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'GIGA+',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      Text(
                        isGigaPlus ? 'Premium Member' : 'Elevate Your Delivery Experience',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isGigaPlus)
                    _buildActiveStatus(context, ref, expiry)
                  else
                    const Text(
                      'Membership Benefits',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 20),
                    _buildBenefitItem(
                    Icons.delivery_dining_rounded,
                    '$currency${(0).toStringAsFixed(0)} Delivery Fees',
                    'Unlimited free delivery on all standard orders over $currency${freeDeliveryThreshold.toStringAsFixed(0)}.',
                  ),
                  _buildBenefitItem(
                    Icons.bolt_rounded,
                    'Priority Logistics',
                    'Get your parcels moved faster with priority rider matching.',
                  ),
                  _buildBenefitItem(
                    Icons.support_agent_rounded,
                    'VIP Support',
                    'Direct access to our premium local support team.',
                  ),
                  _buildBenefitItem(
                    Icons.percent_rounded,
                    'Exclusive Deals',
                    'Monthly coupons and partner discounts across the UK.',
                  ),
                  const SizedBox(height: 40),
                  if (!isGigaPlus)
                    FadeInUp(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Only $currency${price.toStringAsFixed(2)} / month',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Instant professional logistics access.',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final authState = ref.read(authProvider);
                                  if (authState.status != AuthStatus.authenticated) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please log in to join Giga+')),
                                    );
                                    return;
                                  }

                                  try {
                                    // 1. Initialize Stripe
                                    await PaymentService.initialize();
                                    
                                    // 2. Charge Price
                                    final success = await PaymentService.fundWallet(
                                      context, 
                                      price, 
                                      authState.userEmail!, 
                                      authState.userId!
                                    );

                                    if (success) {
                                      // 3. Activate Subscription on Backend
                                      await ref.read(profileProvider.notifier).subscribe();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Welcome to Giga+! Membership active.'),
                                            backgroundColor: AppTheme.successGreen,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('Join Giga+ Now'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: Text(isGigaPlus ? 'Back to Profile' : 'Not now, maybe later'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStatus(BuildContext context, WidgetRef ref, String? expiry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_rounded, color: Colors.green, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Your Membership is Active',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            'Next billing date: ${expiry?.split(' ')[0] ?? 'N/A'}',
            style: TextStyle(color: Colors.green[800]),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () async {
              // Confirm Dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cancel Membership?'),
                  content: const Text('You will lose all Giga+ benefits at the end of your billing cycle. Are you sure?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep Benefits')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true), 
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Confirm Cancel'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // assume we have a cancel method in ProfileNotifier (we need to verify/add it)
                // Actually, ProfileProvider might not have it yet. 
                // Let's check ProfileProvider or use a direct repository call or ad-hoc.
                // Better to add it to ProfileProvider.
                try {
                   // We need to access the provider. 
                   // Accessing via ref.read(profileProvider.notifier).cancelSubscription()
                   // I need to ensure that method exists.
                   // I will assume I need to add it to ProfileProvider first.
                   // For now, I'll put the logic here assuming I'll update provider next.
                   await ref.read(profileProvider.notifier).cancelSubscription();
                   if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Membership cancelled. You still have access until expiry.')),
                     );
                   }
                } catch (e) {
                   if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                   }
                }
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[700],
              side: BorderSide(color: Colors.red[300]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel Membership'),
          ),
        ],
      ),
    );
  }
}
