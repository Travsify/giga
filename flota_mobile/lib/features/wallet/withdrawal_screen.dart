import 'package:flutter/material.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _amountController = TextEditingController();
  final _sortCodeController = TextEditingController();
  final _accountController = TextEditingController();
  bool _isLoading = false;

  Future<void> _processWithdrawal() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum withdrawal is £10')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(userRef);
          final currentBalance = snapshot.data()?['wallet_balance'] ?? 0.0;

          if (currentBalance < amount) {
            throw 'Insufficient funds';
          }

          transaction.update(userRef, {'wallet_balance': currentBalance - amount});
          
          final txRef = userRef.collection('transactions').doc();
          transaction.set(txRef, {
            'amount': -amount,
            'type': 'debit',
            'reference': 'WITHDRAW_${DateTime.now().millisecondsSinceEpoch}',
            'created_at': FieldValue.serverTimestamp(),
            'description': 'Withdrawal to Bank',
            'status': 'pending',
            'details': {
              'sort_code': _sortCodeController.text,
              'account': '****${_accountController.text.substring(_accountController.text.length - 4)}',
            }
          });
        });

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Withdrawal request submitted!')),
           );
           context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw Funds', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                   const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                   const SizedBox(width: 15),
                   const Expanded(child: Text('Funds usually arrive within 2 hours via Faster Payments.')),
                ],
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (£)',
                prefixText: '£ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _sortCodeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Sort Code (6 digits)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _accountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Account Number (8 digits)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Withdraw Funds'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
