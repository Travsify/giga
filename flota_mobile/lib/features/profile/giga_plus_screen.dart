import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/features/profile/profile_provider.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:flota_mobile/core/payment_service.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:flota_mobile/core/settings_service.dart';

class GigaPlusScreen extends ConsumerWidget {
  const GigaPlusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final isGigaPlus = profileState.subscription?['is_giga_plus'] ?? false;
    final expiry = profileState.subscription?['expiry'];

    final settings = ref.watch(settingsServiceProvider);
    final authState = ref.watch(authProvider);
    final isNG = authState.countryCode == 'NG';
    final double basePrice = settings.get<double>('giga_plus_price_gbp', 39.99);
    final double rate = settings.get<double>('ngn_exchange_rate', 2000.0);
    final String displayPrice = isNG 
      ? '${authState.currencySymbol}${(basePrice * rate).toStringAsFixed(0)}' 
      : '${authState.currencySymbol}${basePrice.toStringAsFixed(2)}';

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
                    '${authState.currencySymbol}0 Delivery Fees',
                    'Unlimited free delivery on all standard orders over ${authState.currencySymbol}${isNG ? '15,000' : '15'}.',
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
                    'Monthly coupons and partner discounts across ${isNG ? 'Lagos & Abuja' : 'the UK'}.',
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
                              'Only $displayPrice / month',
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
                                final settings = ref.read(settingsServiceProvider);
                                
                                if (authState.status != AuthStatus.authenticated) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please log in to join Giga+')),
                                  );
                                  return;
                                }

                                try {
                                  final double basePrice = settings.get<double>('giga_plus_price_gbp', 39.99);
                                  final double rate = settings.get<double>('ngn_exchange_rate', 2000.0);
                                  final bool isNG = authState.countryCode == 'NG';
                                  final double finalAmount = isNG ? (basePrice * rate) : basePrice;
                                  final String currency = isNG ? 'NGN' : 'GBP';

                                  bool success = false;

                                  if (isNG) {
                                    // Nigeria → Flutterwave (NGN)
                                    final reference = await PaymentService.fundWithFlutterwave(
                                      context, 
                                      finalAmount, 
                                      currency,
                                    );
                                    
                                    if (reference != null && context.mounted) {
                                      // Show Verification Dialog
                                      final verified = await _showVerificationDialog(context, reference);
                                      if (verified) {
                                        success = true;
                                      }
                                    }
                                  } else {
                                    // UK → Stripe (GBP)
                                    await PaymentService.initialize();
                                    success = await PaymentService.fundWallet(
                                      context, 
                                      finalAmount, 
                                      authState.userEmail!, 
                                      authState.userId!,
                                      currency: currency.toLowerCase(),
                                    );
                                  }

                                    if (success) {
                                      // Payment confirmed → activate subscription
                                      // This will now call the backend which actually deducts the funds
                                      await ref.read(profileProvider.notifier).subscribe();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Welcome to Giga+! Membership active.'),
                                            backgroundColor: AppTheme.successGreen,
                                          ),
                                        );
                                      }
                                    } else {
                                      // Payment was NOT successful — show retry dialog
                                      if (context.mounted) {
                                        _showPaymentFailedDialog(context, ref, 'Payment was declined or cancelled. Please try again.');
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      _showPaymentFailedDialog(context, ref, e.toString());
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

  static Future<bool> _showVerificationDialog(BuildContext context, String reference) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isVerifying = false;
          return AlertDialog(
            backgroundColor: AppTheme.surfaceColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Verify Payment', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Please complete the payment in your browser, then tap verify to activate your membership.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                if (isVerifying) 
                   const Padding(
                     padding: EdgeInsets.all(24.0),
                     child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                   ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false), 
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                onPressed: isVerifying ? null : () async {
                  setDialogState(() => isVerifying = true);
                  // Polling/Verification call
                  final success = await PaymentService.verifyFlutterwavePayment(reference);
                  if (success) {
                    Navigator.pop(ctx, true);
                  } else {
                    setDialogState(() => isVerifying = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment not confirmed yet. Please try again in a moment.')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Verify Now'),
              ),
            ],
          );
        }
      ),
    ) ?? false;
  }

  static void _showPaymentFailedDialog(BuildContext context, WidgetRef ref, String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.payment_rounded, color: Colors.red[400], size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Payment Failed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                errorMessage,
                style: TextStyle(fontSize: 13, color: Colors.red[700]),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your subscription was not activated. You can try again or cancel.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              // Re-trigger the payment — the button's onPressed will run again
              // when user taps 'Join Giga+ Now' after this dialog closes
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tap "Join Giga+ Now" to try again'),
                  backgroundColor: AppTheme.primaryBlue,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
