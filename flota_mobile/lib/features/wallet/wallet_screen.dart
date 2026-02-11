import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flota_mobile/core/payment_service.dart';
import 'package:flota_mobile/features/wallet/withdrawal_screen.dart';
import 'package:flota_mobile/features/wallet/buy_giga_cards_screen.dart';
import 'package:flota_mobile/features/wallet/bill_payment_screen.dart';
import 'wallet_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authState = ref.read(authProvider);
      setState(() {
        _region = (authState.countryCode == 'NG' || authState.countryCode == 'AF') ? 'Africa' : 'UK/Intl';
        _selectedMethod = (_region == 'Africa') ? 'flutterwave' : 'stripe';
      });
      ref.read(walletProvider.notifier).fetchWalletData();
    });
  }

  bool _isLoading = false;
  late String _region; 
  String _selectedMethod = '';

  Future<void> _redeemGiftCard(AuthState authState) async {
    final pinController = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Redeem Giga Card', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              Text('Enter your card PIN to claim credit', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              TextField(
                controller: pinController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 18, letterSpacing: 2),
                decoration: InputDecoration(
                  hintText: 'GIGA-XXXX-XXXX',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.vpn_key, color: AppTheme.primaryRed),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, pinController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Redeem Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final data = await PaymentService.redeemGiftCard(result, authState.userId!);
        await ref.read(walletProvider.notifier).fetchWalletData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully redeemed ${ref.read(authProvider).currencySymbol}${data['amount']}!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.primaryRed));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fundWallet(AuthState authState) async {
    if (authState.userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first')));
      return;
    }

    final amountController = TextEditingController();
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Fund Wallet', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                decoration: InputDecoration(
                  prefixText: '${ref.watch(authProvider).currencySymbol} ',
                  prefixStyle: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                  hintText: '0.00',
                  hintStyle: TextStyle(color: Colors.grey[700]),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final val = double.tryParse(amountController.text);
                    Navigator.pop(context, val);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Add Funds via ${_region == 'Africa' ? 'Flutterwave' : 'Stripe'}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && result > 0) {
      setState(() => _isLoading = true);
      try {
        bool success = false;
        if (_region == 'UK/Intl') {
          await PaymentService.initialize();
          success = await PaymentService.fundWallet(context, result, authState.userEmail!, authState.userId!);
        } else {
          final currency = authState.currencySymbol == '₦' ? 'NGN' : (authState.currencySymbol == '₵' ? 'GHS' : 'USD');
          success = await PaymentService.fundWithFlutterwave(context, result, currency);
        }
        
        if (success) {
          await ref.read(walletProvider.notifier).fetchWalletData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${authState.currencySymbol}${result.toStringAsFixed(2)} added!'), backgroundColor: AppTheme.successGreen),
            );
          }
        } else {
          if (mounted) _showPaymentFailedDialog(context, authState, 'Payment was declined or cancelled. Please try again.', result);
        }
      } catch (e) {
        if (mounted) _showPaymentFailedDialog(context, authState, e.toString(), result);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showPaymentFailedDialog(BuildContext context, AuthState authState, String errorMessage, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: AppTheme.primaryRed, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Payment Failed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
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
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryRed.withOpacity(0.2)),
              ),
              child: Text(
                errorMessage,
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your wallet was not funded. You can try again or check your payment method.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              // Retry with the same amount
              // We simulate result = amount by passing it back to a retry-able path
              // For simplicity in this screen, we tell the user to re-initiate
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please tap Add Funds to try again'), backgroundColor: AppTheme.primaryBlue),
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

  Future<void> _handleWithdraw(AuthState authState) async {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawalScreen()));
  }

  Future<void> _sendFunds(AuthState authState) async {
    final walletState = ref.read(walletProvider);
    final emailController = TextEditingController();
    final amountController = TextEditingController();
    
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Send Funds', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Available: ${authState.currencySymbol}${walletState.balance.toStringAsFixed(2)}', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Recipient's Email",
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  hintText: "Enter recipient email",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.alternate_email, color: AppTheme.accentCyan),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Amount",
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  prefixText: '${authState.currencySymbol} ',
                  prefixStyle: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                  hintText: "0.00",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text);
                    if (emailController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter recipient email')));
                      return;
                    }
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid amount')));
                      return;
                    }
                    if (amount > walletState.balance) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance'), backgroundColor: AppTheme.primaryRed));
                      return;
                    }
                    Navigator.pop(context, {
                      'email': emailController.text.trim(),
                      'amount': amount,
                    });
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Continue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentCyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Confirm Transfer', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '${authState.currencySymbol}${result['amount'].toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                    ),
                    const SizedBox(height: 8),
                    const Icon(Icons.arrow_downward, color: AppTheme.accentCyan),
                    const SizedBox(height: 8),
                    Text(result['email'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This transfer is instant and cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentCyan),
              child: const Text('Send Now'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() => _isLoading = true);
      try {
        final success = await PaymentService.sendFunds(result['email'], result['amount']);
        if (success) {
          await ref.read(walletProvider.notifier).fetchWalletData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${authState.currencySymbol}${result['amount'].toStringAsFixed(2)} sent to ${result['email']}!'),
                backgroundColor: AppTheme.successGreen,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.primaryRed));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _onNavTap(int index, AuthState authState) {
    switch (index) {
      case 0: // Fund
        _fundWallet(authState);
        break;
      case 1: // Gift Cards
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyGigaCardsScreen()));
        break;
      case 2: // Send
        _sendFunds(authState);
        break;
      case 3: // History
        context.push('/transactions');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Giga Wallet', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _redeemGiftCard(authState),
            icon: const Icon(Icons.card_giftcard, color: AppTheme.primaryRed),
            tooltip: 'Redeem Card',
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await ref.read(walletProvider.notifier).fetchWalletData();
            },
            color: AppTheme.primaryRed,
            backgroundColor: AppTheme.surfaceColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Glassmorphism Balance Card
                  FadeInDown(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryBlue,
                            AppTheme.primaryBlue.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text('Total Balance', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, letterSpacing: 1.2)),
                          const SizedBox(height: 12),
                          walletState.isLoading 
                            ? const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(color: Colors.white)))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${authState.currencySymbol} ', style: GoogleFonts.outfit(fontSize: 24, color: Colors.white70, fontWeight: FontWeight.bold)),
                                  Text(
                                    walletState.balance.toStringAsFixed(2),
                                    style: GoogleFonts.outfit(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _CompactActionButton(icon: Icons.add_circle_outline, label: 'Fund', color: Colors.white, onPressed: () => _fundWallet(authState))),
                              const SizedBox(width: 10),
                              Expanded(child: _CompactActionButton(icon: Icons.outbond_outlined, label: 'Withdraw', color: Colors.white, onPressed: () => _handleWithdraw(authState))),
                              const SizedBox(width: 10),
                              Expanded(child: _CompactActionButton(icon: Icons.bolt, label: 'Send', color: AppTheme.accentCyan, onPressed: () => _sendFunds(authState))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 28),

                  // Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.card_giftcard,
                          label: 'Buy Gift Card',
                          color: AppTheme.primaryRed,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyGigaCardsScreen())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.redeem,
                          label: 'Redeem Card',
                          color: AppTheme.successGreen,
                          onTap: () => _redeemGiftCard(authState),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Recent Activity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Activity', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      TextButton(
                        onPressed: () => context.push('/transactions'),
                        child: const Text('See All', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  if (walletState.transactions.isEmpty && !walletState.isLoading)
                    _buildEmptyState()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: walletState.transactions.take(5).length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final tx = walletState.transactions[index];
                        return _ModernTransactionTile(tx: tx, currencySymbol: authState.currencySymbol);
                      },
                    ),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black87,
              child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
            ),
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
          color: AppTheme.surfaceColor,
          border: Border(top: BorderSide(color: AppTheme.borderBlue)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.add_circle_outline, label: 'Fund', onTap: () => _onNavTap(0, authState)),
                _NavItem(icon: Icons.card_giftcard, label: 'Gift Cards', color: AppTheme.primaryRed, onTap: () => _onNavTap(1, authState)),
                _NavItem(icon: Icons.send, label: 'Send', color: AppTheme.accentCyan, onTap: () => _onNavTap(2, authState)),
                _NavItem(icon: Icons.receipt_long, label: 'History', onTap: () => _onNavTap(3, authState)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderBlue),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long, size: 48, color: AppTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No Transactions Yet', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Fund your wallet to get started!', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 12)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? AppTheme.primaryBlue, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color ?? AppTheme.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
          ],
        ),
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _CompactActionButton({required this.icon, required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ModernTransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  final String currencySymbol;

  const _ModernTransactionTile({required this.tx, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
    final isCredit = tx['type'] == 'credit' || amount > 0;
    final status = tx['status'] ?? 'completed';
    
    String formattedDate = '';
    if (tx['created_at'] is Timestamp) {
      formattedDate = DateFormat('MMM dd, HH:mm').format((tx['created_at'] as Timestamp).toDate());
    } else if (tx['created_at'] is String) {
      try {
        formattedDate = DateFormat('MMM dd, HH:mm').format(DateTime.parse(tx['created_at']));
      } catch (e) {
        formattedDate = 'N/A';
      }
    } else {
      formattedDate = 'N/A';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderBlue),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isCredit ? AppTheme.successGreen : AppTheme.primaryRed).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.add : Icons.remove,
              color: isCredit ? AppTheme.successGreen : AppTheme.primaryRed,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['description'] ?? 'Transaction',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(formattedDate, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    if (status != 'completed') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(color: AppTheme.primaryOrange, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : ''}$currencySymbol${amount.abs().toStringAsFixed(2)}',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: isCredit ? AppTheme.successGreen : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
