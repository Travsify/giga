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
  String _selectedMethod = 'stripe'; // Default to stripe

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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Redeem Gift Card', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Enter your 8-digit PIN (e.g., GIGA-100)', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'GIGA-XXXX',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.vpn_key),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, pinController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
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

    if (_selectedMethod == 'gift_card') {
      _redeemGiftCard(authState);
      return;
    }

    // [Input Dialog]
    final amountController = TextEditingController();
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAmountInputSheet(amountController), // Extracted for brevity
    );

    if (amount != null && amount > 0) {
      setState(() => _isLoading = true);
      try {
        await PaymentService.initialize();
        // The backend requires the user to be logged in and the token to be valid.
        // We pass the amount, and internally PaymentService confirms with backend.
        final success = await PaymentService.fundWallet(context, amount, authState.userEmail!, authState.userId!);
        
        if (success) {
          // Refresh Wallet Provider
          await ref.read(walletProvider.notifier).fetchWalletData();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${ref.read(authProvider).currencySymbol}${amount.toStringAsFixed(2)} added!'), backgroundColor: AppTheme.successGreen),
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

  Widget _buildAmountInputSheet(TextEditingController controller) {
    return Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fund Wallet', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '${ref.watch(authProvider).currencySymbol} ',
                prefixStyle: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey),
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.grey[300]),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [10, 25, 50, 100].map((amt) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    onPressed: () => controller.text = amt.toString(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('${ref.read(authProvider).currencySymbol}$amt'),
                  ),
                ),
              )).toList(),
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
                child: Text('Continue to Payment', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send Funds', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Recipient's Email",
                hintText: "Enter friend's email",
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Amount (${ref.watch(authProvider).currencySymbol})",
                hintText: "0.00",
                prefixIcon: const Icon(Icons.attach_money),
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
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Send Now'),
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
          });

          // Add transaction record for recipient
          final recipientTxRef = recipientRef.collection('transactions').doc();
          transaction.set(recipientTxRef, {
            'amount': amount,
            'type': 'credit',
            'description': 'Received from ${authState.userEmail}',
            'created_at': FieldValue.serverTimestamp(),
            'reference': 'RECV_${DateTime.now().millisecondsSinceEpoch}',
          });
        });

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
    final userId = authState.userId;

    // userStream and txStream removed as we use WalletProvider now

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('My Wallet', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _showMoreOptions(authState),
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Blue header background
          Container(height: 120, color: AppTheme.primaryBlue),
          
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                
                // Balance Card
                FadeInDown(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final walletState = ref.watch(walletProvider);
                      final balance = walletState.balance; // Provided by WalletProvider
                      
                      // Trigger fetch on initial load if not loading and balance is 0?
                      // Better done in initState, but let's ensure it's fetched.
                      
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text('Available Balance', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                            const SizedBox(height: 8),
                            walletState.isLoading 
                              ? const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()))
                              : Text(
                                  '${ref.watch(authProvider).currencySymbol}${balance.toStringAsFixed(2)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: _ActionButton(icon: Icons.add, label: 'Fund', onPressed: () => _fundWallet(authState))),
                                const SizedBox(width: 12),
                                Expanded(child: _ActionButton(icon: Icons.arrow_upward, label: 'Withdraw', onPressed: () => context.push('/withdraw'))),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ActionButton(
                                    icon: Icons.send,
                                    label: 'Send',
                                    onPressed: () => _sendFunds(authState),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Payment Methods
                FadeInLeft(
                  delay: const Duration(milliseconds: 100),
                  child: Text('Payment Methods', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 150),
                  child: SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _getPaymentMethods().map((method) {
                        final bool isActive = _selectedMethod == method['id'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12, bottom: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMethod = method['id']!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isActive ? AppTheme.primaryBlue : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    method['icon'] as IconData,
                                    color: isActive ? AppTheme.primaryBlue : Colors.grey[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    method['label'] as String,
                                    style: GoogleFonts.outfit(
                                      color: isActive ? AppTheme.primaryBlue : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (isActive) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: 16),
                                  ]
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Transactions Header
                FadeInLeft(
                  delay: const Duration(milliseconds: 200),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Transactions', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          if (userId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => TransactionListScreen(userId: userId)),
                            );
                          }
                        },
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Transactions List
                Consumer(
                  builder: (context, ref, child) {
                    final walletState = ref.watch(walletProvider);
                    
                    if (walletState.isLoading && walletState.transactions.isEmpty) {
                      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                    }

                    final transactions = walletState.transactions;
                    if (transactions.isEmpty) {
                      return FadeInUp(
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 50, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('No transactions yet', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }

                    return FadeInUp(
                      delay: const Duration(milliseconds: 250),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[100]),
                          itemBuilder: (context, index) {
                            final data = transactions[index];
                            return _TransactionTile(data: data);
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppTheme.primaryBlue.withOpacity(0.1),
        highlightColor: AppTheme.primaryBlue.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryBlue, size: 24),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _PaymentMethodCard({required this.icon, required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: AppTheme.primaryBlue, width: 2) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? AppTheme.primaryBlue : Colors.grey, size: 22),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isActive ? AppTheme.primaryBlue : Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _TransactionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final amount = (data['amount'] ?? 0.0).toDouble();
    final isCredit = data['type'] == 'credit';
    final description = data['description'] ?? 'Transaction';
    final createdAtStr = data['created_at'] as String?;
    final formattedDate = createdAtStr != null 
        ? DateFormat('dd MMM, HH:mm').format(DateTime.parse(createdAtStr)) 
        : '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isCredit ? AppTheme.successGreen.withOpacity(0.1) : AppTheme.errorRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          color: isCredit ? AppTheme.successGreen : AppTheme.errorRed,
          size: 20,
        ),
      ),
      title: Text(description, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(formattedDate, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      trailing: Consumer(
        builder: (context, ref, _) {
          return Text(
            '${isCredit ? '+' : '-'}${ref.read(authProvider).currencySymbol}${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isCredit ? AppTheme.successGreen : AppTheme.errorRed,
            ),
          );
        }
      ),
    );
  }
}
