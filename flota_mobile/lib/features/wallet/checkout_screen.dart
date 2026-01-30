import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/features/marketplace/delivery_provider.dart';
import 'package:flota_mobile/features/marketplace/data/models/delivery_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flota_mobile/core/payment_service.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:flota_mobile/features/profile/profile_provider.dart';
import 'package:flota_mobile/core/settings_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final DeliveryRequest deliveryRequest;
  const CheckoutScreen({super.key, required this.deliveryRequest});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String selectedMethod = 'Giga Wallet';
  bool _hasNhsDiscount = false;
  bool _isCheckingDiscount = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkNhsStatus();
  }

  Future<void> _checkNhsStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _hasNhsDiscount = doc.data()?['has_nhs_discount'] ?? false;
          _isCheckingDiscount = false;
        });
      }
    } else {
      if (mounted) setState(() => _isCheckingDiscount = false);
    }
  }

  double get _effectiveFare {
    final baseFare = widget.deliveryRequest.fare;
    // NHS: Free delivery if order > £20
    if (_hasNhsDiscount && baseFare >= 20) {
      return 0.0;
    }
    return baseFare;
  }

  bool _isGatewayAvailable(WidgetRef ref, String gateway) {
    final countryCode = ref.watch(authProvider).countryCode;
    final settings = ref.read(settingsServiceProvider);
    
    // Find country config
    final country = settings.supportedCountries.firstWhere(
      (c) => c.isoCode == countryCode,
      orElse: () => settings.currentCountry ?? settings.supportedCountries.first
    );
    
    // Check if gateway is in list (or COD feature for COD)
    if (gateway == 'cod') return country.features.contains('cod');
    return country.paymentGateways.contains(gateway);
  }

  Future<void> _handlePayment() async {
    final messenger = ScaffoldMessenger.of(context);
    final profile = ref.read(profileProvider);
    final authState = ref.read(authProvider);
    final user = profile.user;

    // Handle COD
    if (selectedMethod == 'COD') {
       final success = await ref.read(deliveryProvider.notifier).createDelivery(widget.deliveryRequest);
       if (success && mounted) {
          messenger.showSnackBar(const SnackBar(content: Text('Delivery Booked! Please pay safely on arrival.'), backgroundColor: AppTheme.successGreen));
          context.go('/marketplace');
       }
       return;
    }
    
    // Handle Paystack (Stub)
    if (selectedMethod == 'Paystack') {
       messenger.showSnackBar(const SnackBar(content: Text('Paystack integration coming in next update.')));
       return;
    }

    // Handle Stripe
    if (selectedMethod == 'Stripe' || selectedMethod == 'Digital Wallet') {
      if (user == null || user['email'] == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Please wait for profile to load...')),
        );
        return;
      }

      setState(() => _isProcessing = true);
      
      messenger.showSnackBar(
        SnackBar(
          content: Text('Processing ${selectedMethod == 'Stripe' ? 'Card' : 'Digital'} Payment...'),
          duration: const Duration(seconds: 1),
        ),
      );

      try {
        await PaymentService.initialize();
        final userId = authState.userId;
        if (userId == null) throw 'User session expired';

        final paymentSuccess = await PaymentService.fundWallet(
          context, 
          _effectiveFare, 
          user['email'], 
          userId,
          currency: authState.currencyCode?.toLowerCase() ?? 'gbp',
        );

        if (!paymentSuccess) {
          setState(() => _isProcessing = false);
          return; 
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        messenger.showSnackBar(
          SnackBar(content: Text('Payment Error: $e'), backgroundColor: AppTheme.errorRed),
        );
        return;
      }
    }

    final success = await ref.read(deliveryProvider.notifier).createDelivery(widget.deliveryRequest);
    setState(() => _isProcessing = false);
    
    if (success && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Payment Successful & Delivery Booked!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      context.go('/marketplace');
    } else if (mounted) {
      final error = ref.read(deliveryProvider).error ?? 'Transaction failed. Please try again.';
      messenger.showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Decor
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryRed.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
                      ),
                      Text(
                        'Secure Checkout',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInDown(
                          child: Text(
                            "Order Summary",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        FadeInUp(
                          delay: const Duration(milliseconds: 100),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.black.withOpacity(0.05)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _SummaryRow(
                                  label: 'From',
                                  value: widget.deliveryRequest.pickupAddress,
                                  icon: Icons.circle_outlined,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(),
                                ),
                                _SummaryRow(
                                  label: 'To',
                                  value: widget.deliveryRequest.dropoffAddress,
                                  icon: Icons.location_on_rounded,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(),
                                ),
                                _SummaryRow(
                                  label: 'Service Tier',
                                  value: widget.deliveryRequest.serviceTier,
                                  icon: widget.deliveryRequest.serviceTier == 'Priority' 
                                    ? Icons.bolt_rounded 
                                    : (widget.deliveryRequest.serviceTier == 'Saver' ? Icons.eco_rounded : Icons.delivery_dining_rounded),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(),
                                ),
                                _SummaryRow(
                                  label: 'Vehicle',
                                  value: widget.deliveryRequest.vehicleType,
                                  icon: Icons.local_shipping_rounded,
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Fare',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        if (widget.deliveryRequest.fare == 0)
                                          Text(
                                            'Giga+ Benefit Applied',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: AppTheme.successGreen,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      _effectiveFare == 0 ? 'FREE' : '${ref.watch(authProvider).currencySymbol}${_effectiveFare.toStringAsFixed(2)}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: _effectiveFare == 0 ? AppTheme.successGreen : AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                        FadeInLeft(
                          delay: const Duration(milliseconds: 200),
                          child: Text(
                            "Payment Method",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        FadeInUp(
                          delay: const Duration(milliseconds: 300),
                          child: Column(
                            children: [
                              _PaymentOption(
                                title: 'Giga Wallet',
                                subtitle: 'Pay with your digital balance',
                                icon: Icons.account_balance_wallet_rounded,
                                isSelected: selectedMethod == 'Giga Wallet',
                                onTap: () => setState(() => selectedMethod = 'Giga Wallet'),
                              ),
                              if (_isGatewayAvailable(ref, 'stripe')) ...[
                                const SizedBox(height: 12),
                                _PaymentOption(
                                  title: Platform.isAndroid ? 'Google Pay' : 'Apple Pay',
                                  subtitle: 'Secure payment via ${Platform.isAndroid ? 'Google' : 'Apple'}',
                                  icon: Platform.isAndroid ? Icons.android_rounded : Icons.apple_rounded,
                                  isSelected: selectedMethod == 'Digital Wallet',
                                  onTap: () => setState(() => selectedMethod = 'Digital Wallet'),
                                ),
                                const SizedBox(height: 12),
                                _PaymentOption(
                                  title: 'Credit / Debit Card (Stripe)',
                                  subtitle: 'Secure payment via Stripe',
                                  icon: Icons.credit_card_rounded,
                                  isSelected: selectedMethod == 'Stripe',
                                  onTap: () => setState(() => selectedMethod = 'Stripe'),
                                ),
                              ],
                              if (_isGatewayAvailable(ref, 'paystack')) ...[
                                const SizedBox(height: 12),
                                _PaymentOption(
                                  title: 'Paystack',
                                  subtitle: 'Pay with Card, Bank Transfer or USSD',
                                  icon: Icons.credit_score_rounded,
                                  isSelected: selectedMethod == 'Paystack',
                                  onTap: () => setState(() => selectedMethod = 'Paystack'),
                                ),
                              ],
                              if (_isGatewayAvailable(ref, 'cod')) ...[
                                const SizedBox(height: 12),
                                _PaymentOption(
                                  title: 'Cash on Delivery',
                                  subtitle: 'Pay when your package arrives',
                                  icon: Icons.local_atm_rounded,
                                  isSelected: selectedMethod == 'COD',
                                  onTap: () => setState(() => selectedMethod = 'COD'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Confirm Payment Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (deliveryState.isLoading || _isProcessing) ? null : _handlePayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        backgroundColor: AppTheme.primaryBlue,
                        elevation: 0,
                      ),
                      child: (deliveryState.isLoading || _isProcessing)
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Pay and Confirm',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.black26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.black45)),
              Text(
                value,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.black.withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : Colors.black45),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.black45),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue),
          ],
        ),
      ),
    );
  }
}
