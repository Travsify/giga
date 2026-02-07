import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/bill_payment_service.dart';

class BillPaymentScreen extends ConsumerStatefulWidget {
  const BillPaymentScreen({super.key});

  @override
  ConsumerState<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends ConsumerState<BillPaymentScreen> {
  List<dynamic> _allBillers = [];
  List<dynamic> _filteredBillers = [];
  bool _isLoading = true;
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  final Map<String, List<Map<String, dynamic>>> _sections = {
    'E-commerce': [
      {'id': 'ORAIMO', 'name': 'oraimo', 'icon': Icons.shopping_bag_outlined, 'badge': null},
      {'id': 'ALIEXPRESS', 'name': 'AliExpress', 'icon': Icons.shopping_cart_outlined, 'badge': 'NEW'},
      {'id': 'GIFT_CARDS', 'name': 'Gift Cards', 'icon': Icons.card_giftcard, 'badge': null},
      {'id': 'CHOWDECK', 'name': 'Chowdeck', 'icon': Icons.delivery_dining_outlined, 'badge': 'HOT'},
    ],
    'Bills Payment': [
      {'id': 'UTILITY_BILL', 'name': 'Electricity', 'icon': Icons.lightbulb_outline, 'badge': 'HOT'},
      {'id': 'SOLAR', 'name': 'Solar', 'icon': Icons.wb_sunny_outlined, 'badge': null},
      {'id': 'AIRTIME', 'name': 'Airtime', 'icon': Icons.phone_android, 'badge': null},
      {'id': 'DATA_BUNDLE', 'name': 'Data', 'icon': Icons.wifi, 'badge': null},
      {'id': 'CABLE_PAY', 'name': 'TV', 'icon': Icons.tv, 'badge': null},
      {'id': 'INTERNET_SERVICE', 'name': 'Internet', 'icon': Icons.language, 'badge': null},
      {'id': 'ACCOUNT_VERIFICATION', 'name': 'Financial', 'icon': Icons.account_balance_wallet_outlined, 'badge': null},
      {'id': 'GOVERNMENT_PAYMENT', 'name': 'Government', 'icon': Icons.account_balance_outlined, 'badge': null},
      {'id': 'TAX_PAYMENT', 'name': 'Taxes', 'icon': Icons.receipt_long_outlined, 'badge': null},
      {'id': 'RELIGIOUS_INSTITUTIONS', 'name': 'Religious', 'icon': Icons.church_outlined, 'badge': null},
      {'id': 'SCHOOL_FEES', 'name': 'School/Exam', 'icon': Icons.school_outlined, 'badge': null},
      {'id': 'INSURANCE', 'name': 'Insurance', 'icon': Icons.verified_user_outlined, 'badge': null},
    ],
  };

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
          _allBillers = billers.where((b) => b['country'] == 'NG').toList();
          _filterBillers();
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

  void _filterBillers([String? query]) {
    final q = (query ?? _searchController.text).toLowerCase();
    setState(() {
      _filteredBillers = _allBillers.where((b) {
        final matchesQuery = b['name'].toString().toLowerCase().contains(q) || 
                           b['short_name'].toString().toLowerCase().contains(q);
        
        bool matchesCategory = true;
        if (_selectedCategory != null) {
          final billerName = b['biller_name'].toString().toUpperCase();
          matchesCategory = billerName.contains(_selectedCategory!);
        }
        
        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  void _selectCategory(String? categoryId) {
    setState(() {
      if (_selectedCategory == categoryId) {
        _selectedCategory = null;
      } else {
        _selectedCategory = categoryId;
      }
      _filterBillers();
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
        title: Text('All Service', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {}, // Handled by text field below in this refactor, but kept icon for style
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => _filterBillers(v),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search for services...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.accentCyan),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.accentCyan),
              ),
            )
          else if (_selectedCategory == null && _searchController.text.isEmpty) ...[
            for (var entry in _sections.entries) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Text(
                    entry.key,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = entry.value[index];
                      return _ServiceGridItem(
                        name: item['name'],
                        icon: item['icon'],
                        badge: item['badge'],
                        onTap: () => _selectCategory(item['id']),
                      );
                    },
                    childCount: entry.value.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ] else ...[
            // Filtered List View
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final biller = _filteredBillers[index];
                    return Card(
                      color: AppTheme.surfaceColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.accentCyan.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              biller['short_name']?[0] ?? 'B',
                              style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ),
                        title: Text(biller['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(biller['label_name'] ?? 'Ready to pay', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
                        onTap: () => _showPaymentSheet(biller),
                      ),
                    );
                  },
                  childCount: _filteredBillers.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceGridItem extends StatelessWidget {
  final String name;
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;

  const _ServiceGridItem({
    required this.name,
    required this.icon,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Center(
                  child: Icon(icon, color: AppTheme.accentCyan, size: 28),
                ),
              ),
              if (badge != null)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badge == 'HOT' ? AppTheme.primaryRed : AppTheme.successGreen,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (badge == 'HOT' ? AppTheme.primaryRed : AppTheme.successGreen).withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
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
      await BillPaymentService.payBill(
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
