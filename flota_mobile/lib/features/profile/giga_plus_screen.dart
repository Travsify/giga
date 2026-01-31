import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/features/profile/profile_provider.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:flota_mobile/core/payment_service.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:flota_mobile/features/wallet/wallet_provider.dart';

class GigaPlusScreen extends ConsumerWidget {
  const GigaPlusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final isGigaPlus = profileState.subscription?['is_giga_plus'] ?? false;
    final authState = ref.watch(authProvider);
    final expiry = profileState.subscription?['expiry'];
    final walletState = ref.watch(walletProvider);
    final walletBalance = walletState.balance;

    // Dynamic Pricing Logic
    String currencySymbol = '£';
    String currencyIso = 'GBP';
    double price = 39.99;
    double freeDeliveryThreshold = 15.0;

    if (authState.countryCode == 'NG') {
      currencySymbol = '₦';
      currencyIso = 'NGN';
      price = 80000.0; 
      freeDeliveryThreshold = 30000.0;
    } else if (authState.countryCode == 'GH') {
      currencySymbol = '₵';
      currencyIso = 'GHS';
      price = 600.0; // Approx 40 GBP
      freeDeliveryThreshold = 250.0;
    }

    final hasSufficientBalance = walletBalance >= price;

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Membership Benefits',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Balance: $currencySymbol${walletBalance.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                    _buildBenefitItem(
                    Icons.delivery_dining_rounded,
                    '$currencySymbol${(0).toStringAsFixed(0)} Delivery Fees',
                    'Unlimited free delivery on all standard orders over $currencySymbol${freeDeliveryThreshold.toStringAsFixed(0)}.',
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
                              'Only $currencySymbol${price.toStringAsFixed(2)} / month',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Instant professional logistics access.',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            if (hasSufficientBalance)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: profileState.isLoading ? null : () async {
                                    try {
                                      await ref.read(profileProvider.notifier).subscribe(useWallet: true);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Welcome to Giga+! Deducted from wallet.'), backgroundColor: AppTheme.successGreen),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                      }
                                    }
                                  },
                                  icon: profileState.isLoading 
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.account_balance_wallet_rounded),
                                  label: Text(profileState.isLoading ? 'Processing...' : 'Pay with Wallet'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(18),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    backgroundColor: AppTheme.primaryBlue,
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: profileState.isLoading ? null : () async {
                                    final authState = ref.read(authProvider);
                                    if (authState.status != AuthStatus.authenticated) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to join Giga+')));
                                      return;
                                    }

                                    try {
                                      await PaymentService.initialize();
                                      
                                      final success = await PaymentService.fundWallet(
                                        context, 
                                        price, 
                                        authState.userEmail!, 
                                        authState.userId!,
                                        currency: currencyIso
                                      );

                                      if (success) {
                                        await ref.read(profileProvider.notifier).subscribe(useWallet: false);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Welcome to Giga+! Membership active.'), backgroundColor: AppTheme.successGreen),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                      }
                                    }
                                  },
                                  icon: profileState.isLoading 
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.credit_card_rounded),
                                  label: Text(profileState.isLoading ? 'Processing...' : 'Checkout & Join'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(18),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
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
