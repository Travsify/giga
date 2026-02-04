import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/payment_service.dart';
import 'package:flota_mobile/core/error_handler.dart';
import 'package:intl/intl.dart';
import 'wallet_provider.dart';
import 'transaction_list_screen.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(walletProvider.notifier).fetchWalletData());
  }

  bool _isLoading = false;
  String _region = 'UK/Intl'; // Toggle between UK/Intl (Stripe) and Africa (Flutterwave)
  String _selectedMethod = 'stripe';

  List<Map<String, dynamic>> _getPaymentMethods() {
    final methods = [
      {'id': 'stripe', 'label': 'Stripe', 'icon': Icons.credit_card},
      {'id': 'gift_card', 'label': 'Giga Gift Card', 'icon': Icons.card_giftcard},
      {'id': 'giga_card', 'label': 'Giga Card', 'icon': Icons.account_balance_wallet},
    ];

    if (Platform.isIOS) {
      methods.insert(0, {'id': 'apple_pay', 'label': 'Apple Pay', 'icon': Icons.apple});
    } else if (Platform.isAndroid) {
      methods.insert(0, {'id': 'google_pay', 'label': 'Google Pay', 'icon': Icons.payment});
    }

    return methods;
  }

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Redeem Giga Card', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Text('Enter your 8-digit PIN to claim credit', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'GIGA-XXXX',
                filled: true,
                fillColor: AppTheme.surfaceColor,
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
                child: const Text('Redeem Now'),
              ),
            ),
          ],
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
              content: Text('Succesfully redeemed ${ref.read(authProvider).currencySymbol}${data['amount']}!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fundWallet(AuthState authState) async {
    // ... [Validation checks remain same] ...
    if (authState.userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first')));
      return;
    }

    final amountController = TextEditingController();
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAmountInputSheet(amountController), // Extracted for brevity
    );

    if (result != null && result > 0) {
      setState(() => _isLoading = true);
      try {
        bool success = false;
        if (_region == 'UK/Intl') {
          await PaymentService.initialize();
          success = await PaymentService.fundWallet(context, result, authState.userEmail!, authState.userId!);
        } else {
          // African User - Use Flutterwave
          final currency = authState.currencySymbol == '₦' ? 'NGN' : 'GHS';
          success = await PaymentService.fundWithFlutterwave(context, result, currency);
        }
        
        if (success) {
          // Refresh Wallet Provider
          await ref.read(walletProvider.notifier).fetchWalletData();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${authState.currencySymbol}${result.toStringAsFixed(2)} added!'), backgroundColor: AppTheme.successGreen),
            );
          }
        }
      } catch (e) {
        if (mounted) ErrorHandler.handleError(context, e);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleWithdraw(AuthState authState) async {
    final amountController = TextEditingController();
    final accountController = TextEditingController();
    
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Withdraw Funds', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount (${authState.currencySymbol})',
                hintText: '0.00',
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.account_balance_wallet, color: AppTheme.primaryBlue),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: accountController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: _region == 'UK/Intl' ? 'Sort Code & Account Number' : 'Bank Account Number',
                hintText: _region == 'UK/Intl' ? 'XX-XX-XX XXXXXXXX' : 'Enter 10-digit number',
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.account_balance, color: AppTheme.primaryBlue),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  if (amount != null && accountController.text.isNotEmpty) {
                    Navigator.pop(context, {'amount': amount, 'account': accountController.text});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Confirm Withdrawal'),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final success = await PaymentService.withdrawFunds(
          context, 
          result['amount'], 
          result['account'], 
          _region == 'UK/Intl' ? 'stripe' : 'flutterwave'
        );
        
        if (success) {
          await ref.read(walletProvider.notifier).fetchWalletData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Withdrawal request submitted!'), backgroundColor: AppTheme.successGreen),
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildAmountInputSheet(TextEditingController controller) {
    return Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              decoration: InputDecoration(
                prefixText: '${ref.watch(authProvider).currencySymbol} ',
                prefixStyle: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.grey[700]),
                border: InputBorder.none,
                fillColor: Colors.transparent,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(controller.text);
                  Navigator.pop(context, val);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Add Funds via $_region', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
  }

  Future<void> _sendFunds(AuthState authState) async {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send Funds', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Recipient's Email",
                hintText: "Enter friend's email",
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.alternate_email, color: AppTheme.accentCyan),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Amount (${authState.currencySymbol})",
                hintText: "0.00",
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.send, color: AppTheme.accentCyan),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  if (emailController.text.isNotEmpty && amount != null && amount > 0) {
                    Navigator.pop(context, {
                      'email': emailController.text.trim(),
                      'amount': amount,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Send Instant'),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final String recipientEmail = result['email'];
      final double amount = result['amount'];

      setState(() => _isLoading = true);
      try {
        // 1. Find recipient by email
        final recipientQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: recipientEmail)
            .limit(1)
            .get();

        if (recipientQuery.docs.isEmpty) throw 'Recipient not found';
        
        final recipientDoc = recipientQuery.docs.first;
        final recipientId = recipientDoc.id;

        if (recipientId == authState.userId) throw 'You cannot send funds to yourself';

        // 2. Perform atomic transaction
        final senderRef = FirebaseFirestore.instance.collection('users').doc(authState.userId);
        final recipientRef = FirebaseFirestore.instance.collection('users').doc(recipientId);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final senderSnap = await transaction.get(senderRef);
          final senderBalance = (senderSnap.data()?['wallet_balance'] ?? 0.0).toDouble();

          if (senderBalance < amount) throw 'Insufficient funds';

          // Update sender
          transaction.update(senderRef, {'wallet_balance': senderBalance - amount});
          
          // Update recipient
          final recipientSnap = await transaction.get(recipientRef);
          final recipientBalance = (recipientSnap.data()?['wallet_balance'] ?? 0.0).toDouble();
          transaction.update(recipientRef, {'wallet_balance': recipientBalance + amount});

          // Add transaction record for sender
          final senderTxRef = senderRef.collection('transactions').doc();
          transaction.set(senderTxRef, {
            'amount': -amount,
            'type': 'debit',
            'description': 'Sent to $recipientEmail',
            'created_at': FieldValue.serverTimestamp(),
            'reference': 'SEND_${DateTime.now().millisecondsSinceEpoch}',
            'status': 'completed',
          });

          // Add transaction record for recipient
          final recipientTxRef = recipientRef.collection('transactions').doc();
          transaction.set(recipientTxRef, {
            'amount': amount,
            'type': 'credit',
            'description': 'Received from ${authState.userEmail}',
            'created_at': FieldValue.serverTimestamp(),
            'reference': 'RECV_${DateTime.now().millisecondsSinceEpoch}',
            'status': 'completed',
          });
        });

        await ref.read(walletProvider.notifier).fetchWalletData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Funds sent successfully!'), backgroundColor: AppTheme.successGreen),
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showMoreOptions(AuthState authState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.history, color: AppTheme.primaryBlue),
              title: const Text('Transaction History'),
              onTap: () {
                Navigator.pop(context);
                if (authState.userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TransactionListScreen(userId: authState.userId!)),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card, color: AppTheme.primaryBlue),
              title: const Text('Manage Payment Methods'),
              onTap: () {
                Navigator.pop(context);
                context.push('/payment-methods');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: AppTheme.primaryBlue),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                context.push('/support');
              },
            ),
          ],
        ),
      ),
    );
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
          IconButton(
            onPressed: () => _showMoreOptions(authState),
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Region Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderBlue),
                  ),
                  child: Row(
                    children: ['UK/Intl', 'Africa'].map((r) {
                      final active = _region == r;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _region = r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: active ? AppTheme.primaryBlue : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                r,
                                style: TextStyle(
                                  color: active ? Colors.white : AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Glassmorphism Balance Card
                FadeInDown(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
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
                                    fontSize: 52,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(child: _CompactActionButton(icon: Icons.add_circle_outline, label: 'Fund', color: Colors.white, onPressed: () => _fundWallet(authState))),
                            const SizedBox(width: 12),
                            Expanded(child: _CompactActionButton(icon: Icons.outbond_outlined, label: 'Withdraw', color: Colors.white, onPressed: () => _handleWithdraw(authState))),
                            const SizedBox(width: 12),
                            Expanded(child: _CompactActionButton(icon: Icons.bolt, label: 'Send', color: AppTheme.accentCyan, onPressed: () => _sendFunds(authState))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),

                // Recent Activity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Global Activity', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    TextButton(
                      onPressed: () => context.push('/transactions'),
                      child: Text('History', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
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
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tx = walletState.transactions[index];
                      return _ModernTransactionTile(tx: tx, currencySymbol: authState.currencySymbol);
                    },
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black87,
              child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
            ),
        ],
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
          Text('Top up your wallet to start!', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 12)),
        ],
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
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
    final amount = (tx['amount'] ?? 0.0).toDouble();
    final isCredit = tx['type'] == 'credit' || amount > 0;
    final status = tx['status'] ?? 'completed';
    
    // Handle FieldValue.serverTimestamp() for created_at
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
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
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['description'] ?? 'Transaction',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
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
            '${isCredit ? '+' : ''}${currencySymbol}${amount.abs().toStringAsFixed(2)}',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: isCredit ? AppTheme.successGreen : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
