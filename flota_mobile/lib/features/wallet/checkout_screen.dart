import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/features/marketplace/delivery_provider.dart';
import 'package:flota_mobile/features/marketplace/data/models/delivery_models.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final DeliveryRequest deliveryRequest;
  const CheckoutScreen({super.key, required this.deliveryRequest});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String selectedMethod = 'Giga Wallet';

  Future<void> _handlePayment() async {
    if (selectedMethod == 'Stripe') {
      // Simulate Stripe Payment Sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing Card Payment via Stripe...')),
      );
      await Future.delayed(const Duration(seconds: 2));
    }

    final success = await ref.read(deliveryProvider.notifier).createDelivery(widget.deliveryRequest);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery Booked Successfully!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      // Navigate to tracking or home
      context.go('/marketplace');
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
                                      widget.deliveryRequest.fare == 0 ? 'FREE' : '£${widget.deliveryRequest.fare.toStringAsFixed(2)}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: widget.deliveryRequest.fare == 0 ? AppTheme.successGreen : AppTheme.primaryBlue,
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
                              const SizedBox(height: 12),
                              _PaymentOption(
                                title: 'Apple Pay',
                                subtitle: 'Secure payment via Apple',
                                icon: Icons.apple_rounded,
                                isSelected: selectedMethod == 'Apple Pay',
                                onTap: () => setState(() => selectedMethod = 'Apple Pay'),
                              ),
                              const SizedBox(height: 12),
                              _PaymentOption(
                                title: 'Debit / Credit Card',
                                subtitle: 'Powered by Stripe',
                                icon: Icons.credit_card_rounded,
                                isSelected: selectedMethod == 'Stripe',
                                onTap: () => setState(() => selectedMethod = 'Stripe'),
                              ),
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
                      onPressed: deliveryState.isLoading ? null : _handlePayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        backgroundColor: AppTheme.primaryBlue,
                        elevation: 0,
                      ),
                      child: deliveryState.isLoading
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
