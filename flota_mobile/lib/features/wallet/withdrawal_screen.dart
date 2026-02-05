import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:flota_mobile/features/wallet/wallet_provider.dart';
import 'package:flota_mobile/core/api_client.dart';
import 'package:flota_mobile/features/tracking/rider_earnings_screen.dart'; // Reuse bank provider
import 'package:dio/dio.dart';
import 'package:animate_do/animate_do.dart';

class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  BankAccount? _selectedBank;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).fetchWalletData();
      ref.read(bankAccountsProvider); // Trigger fetch
    });
  }

  Future<void> _processWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;
    
    final wallet = ref.read(walletProvider);
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    if (amount > wallet.balance) {
      _showError('Insufficient funds. You have ${wallet.balance}.');
      return;
    }

    if (_selectedBank == null) {
      _showError('Please select a bank account.');
      return;
    }

    setState(() => _isLoading = true);
    final api = ref.read(apiClientProvider);

    try {
      final response = await api.dio.post('wallet/withdraw', data: {
        'amount': amount,
        'bank_account_id': _selectedBank!.id,
      });

      if (response.data['status'] == 'success') {
        ref.read(walletProvider.notifier).fetchWalletData();
        if (mounted) {
           _showSuccessDialog(amount);
        }
      }
    } catch (e) {
      String msg = 'Withdrawal Failed';
      if (e is DioException) {
        msg = e.response?.data['error'] ?? e.response?.data['message'] ?? e.message ?? 'Server connection failed';
      } else {
        msg = e.toString();
      }
      _showError(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.borderBlue)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 60),
            const SizedBox(height: 20),
            Text('Withdrawal Submitted!', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            Text(
              '${ref.read(authProvider).currencySymbol}${amount.toStringAsFixed(2)} will arrive shortly.', 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final banksAsync = ref.watch(bankAccountsProvider);
    final currencySymbol = ref.read(authProvider).currencySymbol;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('WITHDRAW FUNDS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              FadeInDown(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryBlue, Color(0xFF1E3A5F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Available Balance', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text('$currencySymbol${wallet.balance.toStringAsFixed(2)}', 
                               style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const Icon(Icons.account_balance_wallet, color: Colors.white24, size: 48),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Amount
              Text('ENTER AMOUNT', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              FadeInLeft(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  decoration: InputDecoration(
                    prefixText: '$currencySymbol ',
                    prefixStyle: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    hintText: '0.00',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.borderBlue)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2)),
                  ),
                  validator: (v) {
                    final val = double.tryParse(v ?? '') ?? 0;
                    if (val < 10) return 'Min withdrawal 10';
                    if (val > wallet.balance) return 'Insufficient funds';
                    return null;
                  },
                ),
              ),
              
              const SizedBox(height: 24),

              // Bank Selection
              Text('PAYOUT DESTINATION', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              FadeInRight(
                child: banksAsync.when(
                  data: (banks) => DropdownButtonFormField<BankAccount>(
                    value: _selectedBank,
                    items: banks.map((bank) => DropdownMenuItem(
                      value: bank,
                      child: Text('${bank.bankName} - ••${bank.accountNumber.substring(bank.accountNumber.length.clamp(2, 10) - 2)}', style: const TextStyle(color: Colors.white)),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedBank = val),
                    dropdownColor: AppTheme.surfaceColor,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.borderBlue)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2)),
                    ),
                    hint: const Text('Select Bank Account', style: TextStyle(color: Colors.white54)),
                  ),
                  loading: () => const LinearProgressIndicator(color: AppTheme.primaryBlue),
                  error: (e, s) => Text('Error loading banks: $e', style: const TextStyle(color: AppTheme.primaryRed)),
                ),
              ),

              const SizedBox(height: 40),
              FadeInUp(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _processWithdrawal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoading ? Colors.grey : AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      elevation: 8,
                      shadowColor: AppTheme.primaryBlue.withOpacity(0.5),
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : Text('WITHDRAW FUNDS', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
