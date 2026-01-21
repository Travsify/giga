import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/payment_service.dart';
import 'package:flota_mobile/core/error_handler.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _isLoading = false;

  Future<void> _fundWallet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;

    final amountController = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fund Wallet'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (₦)',
            hintText: 'e.g. 5000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(amountController.text);
              Navigator.pop(context, val);
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );

    if (amount != null && amount > 0) {
      setState(() => _isLoading = true);
      
      try {
        await PaymentService.initialize();
        // Pass context correctly now
        final success = await PaymentService.fundWallet(context, amount, user!.email!);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Wallet funded successfully!'), backgroundColor: AppTheme.successGreen),
            );
          }
        } else {
          throw 'Payment cancelled or failed';
        }
      } catch (e) {
        if (mounted) ErrorHandler.handleError(context, e);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    // Real-time listener for user wallet
    final userStream = FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots();
    // Real-time listener for transactions
    final txStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('transactions')
        .orderBy('created_at', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: userStream,
                  builder: (context, snapshot) {
                     final balance = snapshot.data?.data() != null 
                        ? (snapshot.data!.get('wallet_balance') ?? 0.0) 
                        : 0.0;
                     
                     return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryBlue, AppTheme.accentCyan],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Balance', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 5),
                          Text(
                            '₦${balance.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _ActionButton(
                                icon: Icons.add,
                                label: 'Fund',
                                onPressed: _fundWallet,
                              ),
                              const SizedBox(width: 20),
                              _ActionButton(
                                icon: Icons.arrow_upward,
                                label: 'Withdraw',
                                onPressed: () {
                                  ErrorHandler.handleError(context, 'Withdrawal feature coming soon!');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Transactions', style: Theme.of(context).textTheme.displayMedium),
                    TextButton(onPressed: () {}, child: const Text('See All')),
                  ],
                ),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: txStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const Text('Error loading transactions');
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('No transactions yet.', style: TextStyle(color: Colors.white54)),
                      );
                    }

                    return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final amount = data['amount'] ?? 0;
                          final isDebit = data['type'] == 'debit';
                          
                          return _TransactionItem(
                            title: data['description'] ?? 'Transaction',
                            subtitle: 'Details', // Format timestamp here if needed
                            amount: '₦$amount',
                            isDebit: isDebit,
                          );
                        },
                      );
                  }
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
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
    return InkWell(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final bool isDebit;
  const _TransactionItem({required this.title, required this.subtitle, required this.amount, required this.isDebit});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isDebit ? Icons.shopping_basket : Icons.account_balance_wallet,
          color: isDebit ? AppTheme.errorRed : AppTheme.successGreen,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.slateBlue)),
      trailing: Text(
        amount,
        style: TextStyle(
          color: isDebit ? AppTheme.errorRed : AppTheme.successGreen,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
