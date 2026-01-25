import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/api_client.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _billingData;

  @override
  void initState() {
    super.initState();
    _fetchBilling();
  }

  Future<void> _fetchBilling() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.get('business/billing');
      setState(() {
        _billingData = response.data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch billing: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Billing & Credit', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchBilling,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildCreditCard(),
                  const SizedBox(height: 32),
                  Text('Invoice History', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  ...(_billingData?['invoices'] as List? ?? []).map((inv) => _InvoiceItem(
                        invoice: inv,
                        currencySymbol: ref.watch(authProvider).currencySymbol,
                      )),
                  if ((_billingData?['invoices'] as List? ?? []).isEmpty)
                    const Center(child: Text('No invoices found.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
                ],
              ),
            ),
    );
  }

  Widget _buildCreditCard() {
    final limit = double.tryParse(_billingData?['credit_limit']?.toString() ?? '0.0') ?? 0.0;
    final balance = double.tryParse(_billingData?['outstanding_balance']?.toString() ?? '0.0') ?? 0.0;
    final available = limit - balance;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Available Credit', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
              const Icon(Icons.credit_card_rounded, color: Colors.white38),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${ref.watch(authProvider).currencySymbol}${available.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _subMetric('CREDIT LIMIT', '${ref.watch(authProvider).currencySymbol}${limit.toStringAsFixed(2)}'),
              const SizedBox(width: 40),
              _subMetric('OUTSTANDING', '${ref.watch(authProvider).currencySymbol}${balance.toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _InvoiceItem extends StatelessWidget {
  final dynamic invoice;
  final String currencySymbol;
  const _InvoiceItem({required this.invoice, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.receipt_rounded, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invoice #${invoice['id']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(invoice['date'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$currencySymbol${invoice['amount'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Text(invoice['status'], style: TextStyle(color: invoice['status'] == 'Paid' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
