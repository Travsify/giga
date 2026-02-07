import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../core/bill_payment_service.dart';
import '../auth/auth_provider.dart';

class BillPaymentScreen extends ConsumerStatefulWidget {
  const BillPaymentScreen({super.key});

  @override
  ConsumerState<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends ConsumerState<BillPaymentScreen> {
  List<dynamic> _allBillers = [];
  List<dynamic> _filteredBillers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBillers();
  }

  Future<void> _fetchBillers() async {
    try {
      final billers = await BillPaymentService.getCategories();
      if (mounted) {
        setState(() {
          // Filter for NG for now, or use user's country code if available
          // API returns country code like "NG", "GH", "KE"
          _allBillers = billers.where((b) => b['country'] == 'NG').toList();
          _filteredBillers = _allBillers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading billers: $e')));
      }
    }
  }

  void _filterBillers(String query) {
    setState(() {
      _searchQuery = query;
      _filteredBillers = _allBillers.where((b) {
        final name = b['name'].toString().toLowerCase();
        final shortName = b['short_name'].toString().toLowerCase();
        return name.contains(query.toLowerCase()) || shortName.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _showPaymentSheet(dynamic biller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BillPaymentSheet(biller: biller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Pay Bills', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterBillers,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for Airtime, Data, TV...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: AppTheme.accentCyan),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
                : ListView.builder(
                    itemCount: _filteredBillers.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final biller = _filteredBillers[index];
                      return Card(
                        color: AppTheme.surfaceColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                            child: Text(biller['short_name']?[0] ?? 'B', style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(biller['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(biller['label_name'] ?? 'Enter details', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                          onTap: () => _showPaymentSheet(biller),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BillPaymentSheet extends StatefulWidget {
  final dynamic biller;
  const _BillPaymentSheet({required this.biller});

  @override
  State<_BillPaymentSheet> createState() => _BillPaymentSheetState();
}

class _BillPaymentSheetState extends State<_BillPaymentSheet> {
  final _customerController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _customerName;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    if (widget.biller['amount'] > 0) {
      _amountController.text = widget.biller['amount'].toString();
    }
  }

  Future<void> _validate() async {
    setState(() { _isLoading = true; _validationError = null; });
    try {
      final res = await BillPaymentService.validateCustomer(
        widget.biller['item_code'],
        widget.biller['biller_code'],
        _customerController.text,
      );
      setState(() {
        _customerName = res['name'] ?? res['customer_name'] ?? 'Verified Customer';
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _validationError = e.toString(); });
    }
  }

  Future<void> _pay() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);
    try {
      final res = await BillPaymentService.payBill(
        amount: amount,
        type: widget.biller['biller_name'], // Should ideally be item_code or biller_name depending on API requirement. Using biller_name as generic type.
        customer: _customerController.text,
        country: widget.biller['country'],
        billerName: widget.biller['name'],
      );
      
      if (mounted) {
        Navigator.pop(context); // Close sheet
        Navigator.pop(context); // Close screen (optional)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful!'), backgroundColor: AppTheme.successGreen));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.primaryRed));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if validation is needed based on label_name or biller type? 
    // Usually validation is needed for TV and Power. Airtime might not support validation.
    // Logic: If user enters ID, show "Verify" button. If verified or not supported, show "Pay".
    // For simplicity, we assume validation is optional/supported if user wants to check name.
    
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.biller['name'], style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            TextField(
              controller: _customerController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: widget.biller['label_name'] ?? 'Customer ID',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle, color: AppTheme.accentCyan),
                  onPressed: _validate,
                  tooltip: 'Verify Customer',
                ),
              ),
            ),
            if (_isLoading && _customerName == null) const LinearProgressIndicator(),
            if (_validationError != null)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(_validationError!, style: const TextStyle(color: AppTheme.primaryRed))),
            if (_customerName != null)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text('Verfied: $_customerName', style: const TextStyle(color: AppTheme.successGreen))),
            
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              readOnly: widget.biller['amount'] > 0,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading ? const CircularProgressIndicator() : const Text('Pay Bill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
