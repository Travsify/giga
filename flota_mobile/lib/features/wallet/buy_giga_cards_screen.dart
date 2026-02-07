import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:flota_mobile/core/payment_service.dart';
import 'package:flota_mobile/features/wallet/wallet_provider.dart';
import 'package:flota_mobile/core/api_client.dart';
import 'package:share_plus/share_plus.dart';

class BuyGigaCardsScreen extends ConsumerStatefulWidget {
  const BuyGigaCardsScreen({super.key});

  @override
  ConsumerState<BuyGigaCardsScreen> createState() => _BuyGigaCardsScreenState();
}

class _BuyGigaCardsScreenState extends ConsumerState<BuyGigaCardsScreen> {
  bool _isLoading = false;
  int? _selectedDenomination;
  String? _generatedPin;
  double? _generatedAmount;

  List<Map<String, dynamic>> _getDenominations(String currency) {
    if (currency == '₦') {
      return [
        {'amount': 1000, 'label': '₦1,000', 'popular': false},
        {'amount': 2000, 'label': '₦2,000', 'popular': false},
        {'amount': 5000, 'label': '₦5,000', 'popular': true},
        {'amount': 10000, 'label': '₦10,000', 'popular': false},
        {'amount': 25000, 'label': '₦25,000', 'popular': false},
        {'amount': 50000, 'label': '₦50,000', 'popular': false},
      ];
    } else {
      return [
        {'amount': 5, 'label': '£5', 'popular': false},
        {'amount': 10, 'label': '£10', 'popular': false},
        {'amount': 25, 'label': '£25', 'popular': true},
        {'amount': 50, 'label': '£50', 'popular': false},
        {'amount': 100, 'label': '£100', 'popular': false},
      ];
    }
  }


  Future<void> _purchaseCard() async {
    if (_selectedDenomination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a card value')),
      );
      return;
    }

    final authState = ref.read(authProvider);
    final walletState = ref.read(walletProvider);
    final amount = _selectedDenomination!.toDouble();

    // Check balance
    if (walletState.balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Insufficient balance. Please fund your wallet first.'),
          backgroundColor: AppTheme.primaryRed,
          action: SnackBarAction(
            label: 'Fund',
            textColor: Colors.white,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
      return;
    }

    // Confirm purchase
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Confirm Purchase', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_giftcard, color: AppTheme.primaryRed, size: 48),
            const SizedBox(height: 16),
            Text(
              '${authState.currencySymbol}${_selectedDenomination!.toStringAsFixed(0)}',
              style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text('Giga Gift Card', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            Text(
              'This will deduct from your wallet balance.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      /*
      // Generate mock PIN for now (backend endpoint needed)
      final pin = _generateMockPin();
      
      // In production, this would call: PaymentService.purchaseGiftCard(amount)
      // For now, simulating the purchase
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _generatedPin = pin;
        _generatedAmount = amount;
      });
      */

      // Real API Call
      final api = ref.read(apiClientProvider);
      final response = await api.dio.post('wallet/giftcard/purchase', data: {
        'amount': amount,
        'currency': authState.currencyCode, // Ensure AuthState has currencyCode
      });

      if (response.data['status'] == 'success') {
        final card = response.data['card'];
        setState(() {
          _generatedPin = card['code'];
          _generatedAmount = (card['amount'] as num).toDouble();
        });

        // Refresh wallet
        await ref.read(walletProvider.notifier).fetchWalletData();

        _showSuccessSheet();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e'), backgroundColor: AppTheme.primaryRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _generateMockPin() {
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String pin = 'GIGA-';
    for (int i = 0; i < 4; i++) {
      pin += chars[(random + i * 7) % chars.length];
    }
    pin += '-';
    for (int i = 0; i < 4; i++) {
      pin += chars[(random + i * 11) % chars.length];
    }
    return pin;
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 64),
            const SizedBox(height: 16),
            Text('Card Created!', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryRed, AppTheme.primaryRed.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('GIGA GIFT CARD', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, letterSpacing: 2)),
                  const SizedBox(height: 12),
                  Text(
                    '${ref.read(authProvider).currencySymbol}${_generatedAmount?.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_generatedPin ?? '', style: GoogleFonts.robotoMono(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _generatedPin ?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PIN copied!'), duration: Duration(seconds: 1)),
                            );
                          },
                          icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Share.share(
                        '🎁 Here\'s a Giga Gift Card for you!\n\nValue: ${ref.read(authProvider).currencySymbol}${_generatedAmount?.toStringAsFixed(0)}\nPIN: $_generatedPin\n\nRedeem at app.gigalogistics.com',
                        subject: 'Giga Gift Card',
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close sheet
                      Navigator.pop(context); // Close screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final walletState = ref.watch(walletProvider);
    final denominations = _getDenominations(authState.currencySymbol);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Buy Giga Cards', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryRed.withOpacity(0.1), AppTheme.primaryBlue.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard, color: AppTheme.primaryRed, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Giga Gift Cards', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Purchase & share with friends. Redeemable instantly!', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Wallet Balance
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderBlue),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Balance', style: TextStyle(color: AppTheme.textSecondary)),
                  Text(
                    '${authState.currencySymbol}${walletState.balance.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Select Value
            Text('SELECT CARD VALUE', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: denominations.length,
              itemBuilder: (context, index) {
                final denom = denominations[index];
                final isSelected = _selectedDenomination == denom['amount'];
                final isPopular = denom['popular'] == true;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDenomination = denom['amount']),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryRed.withOpacity(0.15) : AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryRed : AppTheme.borderBlue,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            denom['label'],
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppTheme.primaryRed : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (isPopular)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Popular', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      if (isSelected)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AppTheme.primaryRed, shape: BoxShape.circle),
                            child: const Icon(Icons.check, color: Colors.white, size: 14),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Purchase Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isLoading || _selectedDenomination == null) ? null : _purchaseCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  disabledBackgroundColor: AppTheme.primaryRed.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _selectedDenomination != null
                            ? 'Purchase ${authState.currencySymbol}${_selectedDenomination!.toStringAsFixed(0)} Card'
                            : 'Select a Value',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Terms
            Center(
              child: Text(
                'Gift cards are non-refundable. Valid for 12 months.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
