import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/features/wallet/wallet_provider.dart';
import 'package:flota_mobile/features/wallet/transaction_export_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  final String userId;
  const TransactionListScreen({super.key, required this.userId});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).fetchWalletData();
    });
  }

  Future<void> _exportPDF() async {
    final walletState = ref.read(walletProvider);
    final authState = ref.read(authProvider);
    
    if (walletState.transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export')),
      );
      return;
    }

    setState(() => _isExporting = true);
    
    try {
      await TransactionExportService.shareTransactions(
        transactions: walletState.transactions,
        userName: authState.userName ?? authState.userEmail ?? 'User',
        currencySymbol: authState.currencySymbol,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppTheme.primaryRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _shareAsText() {
    final walletState = ref.read(walletProvider);
    final authState = ref.read(authProvider);
    
    if (walletState.transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to share')),
      );
      return;
    }

    final text = TransactionExportService.generateTextSummary(
      transactions: walletState.transactions,
      currencySymbol: authState.currencySymbol,
    );
    
    Share.share(text, subject: 'Giga Transaction History');
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Transaction History', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!walletState.isLoading && walletState.transactions.isNotEmpty) ...[
            IconButton(
              onPressed: _shareAsText,
              icon: const Icon(Icons.share, size: 22),
              tooltip: 'Share as Text',
            ),
            IconButton(
              onPressed: _isExporting ? null : _exportPDF,
              icon: _isExporting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf, size: 22),
              tooltip: 'Download PDF',
            ),
          ],
        ],
      ),
      body: walletState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
          : walletState.transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 80, color: AppTheme.textSecondary.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text('No transactions yet', style: GoogleFonts.outfit(fontSize: 18, color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      Text('Your transaction history will appear here', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6))),
                      if (walletState.error != null)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(walletState.error!, style: const TextStyle(color: AppTheme.primaryRed), textAlign: TextAlign.center),
                        )
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryBlue.withOpacity(0.8), AppTheme.primaryBlue],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SummaryItem(
                            label: 'Total',
                            value: '${walletState.transactions.length}',
                            icon: Icons.receipt_long,
                          ),
                          Container(width: 1, height: 40, color: Colors.white24),
                          _SummaryItem(
                            label: 'Credits',
                            value: _countByType(walletState.transactions, true).toString(),
                            icon: Icons.arrow_downward,
                            color: AppTheme.successGreen,
                          ),
                          Container(width: 1, height: 40, color: Colors.white24),
                          _SummaryItem(
                            label: 'Debits',
                            value: _countByType(walletState.transactions, false).toString(),
                            icon: Icons.arrow_upward,
                            color: AppTheme.primaryRed,
                          ),
                        ],
                      ),
                    ),
                    
                    // Transaction List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: walletState.transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final data = walletState.transactions[index];
                          return _TransactionTile(
                            data: data,
                            currencySymbol: authState.currencySymbol,
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  int _countByType(List<Map<String, dynamic>> transactions, bool credits) {
    return transactions.where((tx) {
      final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
      final isCredit = tx['type'] == 'credit' || amount > 0;
      return credits ? isCredit : !isCredit;
    }).length;
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _SummaryItem({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.white, size: 20),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String currencySymbol;
  const _TransactionTile({required this.data, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
    final isCredit = data['type'] == 'credit' || amount > 0;
    final description = data['description'] ?? 'Transaction';
    final createdAtStr = data['created_at'] as String?;
    final formattedDate = createdAtStr != null 
        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(createdAtStr)) 
        : '';

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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isCredit ? AppTheme.successGreen : AppTheme.primaryRed).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? AppTheme.successGreen : AppTheme.primaryRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                const SizedBox(height: 4),
                Text(formattedDate, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}$currencySymbol${amount.abs().toStringAsFixed(2)}',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isCredit ? AppTheme.successGreen : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
