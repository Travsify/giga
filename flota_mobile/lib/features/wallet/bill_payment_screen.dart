import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/bill_payment_service.dart';
import 'package:flota_mobile/features/profile/profile_provider.dart';

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
    'Airtime & Data': [
      {'id': 'AIRTIME', 'name': 'Airtime', 'icon': Icons.phone_android, 'badge': 'HOT'},
      {'id': 'DATA_BUNDLE', 'name': 'Mobile Data', 'icon': Icons.wifi, 'badge': null},
    ],
    'Entertainment': [
      {'id': 'CABLE_PAY', 'name': 'Cable TV', 'icon': Icons.tv, 'badge': null},
      {'id': 'SHOWMAX', 'name': 'Showmax', 'icon': Icons.live_tv, 'badge': 'NEW'},
      {'id': 'BETTING', 'name': 'Sport Betting', 'icon': Icons.sports_soccer_outlined, 'badge': 'HOT'},
    ],
    'Utilities': [
      {'id': 'UTILITY_BILL', 'name': 'Electricity', 'icon': Icons.lightbulb_outline, 'badge': 'HOT'},
      {'id': 'SOLAR', 'name': 'Solar Energy', 'icon': Icons.wb_sunny_outlined, 'badge': null},
    ],
    'Internet & More': [
      {'id': 'INTERNET_SERVICE', 'name': 'Home Internet', 'icon': Icons.language, 'badge': null},
      {'id': 'GIFT_CARDS', 'name': 'Gift Cards', 'icon': Icons.card_giftcard, 'badge': null},
    ],
    'Financials & Tax': [
      {'id': 'TAX_PAYMENT', 'name': 'LIRS Taxes', 'icon': Icons.receipt_long_outlined, 'badge': null},
      {'id': 'GOVERNMENT_PAYMENT', 'name': 'Govt Payment', 'icon': Icons.account_balance_outlined, 'badge': null},
      {'id': 'SCHOOL_FEES', 'name': 'Edu & Exams', 'icon': Icons.school_outlined, 'badge': null},
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
          
          // Discover available categories from API
          final availableCategories = _allBillers
              .map((b) => _getCategoryForBiller(Map<String, dynamic>.from(b)))
              .where((c) => c != null)
              .toSet();

          // Dynamically filter sections
          final Map<String, List<Map<String, dynamic>>> activeSections = {};
          
          _sections.forEach((title, items) {
            final filteredItems = items.where((item) {
              return availableCategories.contains(item['id']);
            }).toList();
            
            if (filteredItems.isNotEmpty) {
              activeSections[title] = filteredItems;
            }
          });

          // Update sections with only active ones
          _sections.clear();
          _sections.addAll(activeSections);

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
        final name = (b['name'] ?? '').toString().toLowerCase();
        final shortName = (b['short_name'] ?? '').toString().toLowerCase();
        
        final matchesQuery = q.isEmpty || name.contains(q) || shortName.contains(q);
        
        bool matchesCategory = true;
        if (_selectedCategory != null) {
          final billerCategory = _getCategoryForBiller(b);
          matchesCategory = billerCategory == _selectedCategory;
        }
        
        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  String? _getCategoryForBiller(Map<String, dynamic> biller) {
    if (biller['is_airtime'] == true) return 'AIRTIME';
    
    final String itemCode = (biller['item_code'] ?? '').toString().toUpperCase();
    final String billerName = (biller['biller_name'] ?? '').toString().toUpperCase();
    
    if (itemCode.startsWith('MD') || billerName.contains('DATA')) return 'DATA_BUNDLE';
    if (itemCode.startsWith('CB') || billerName.contains('CABLE') || billerName.contains('DSTV') || billerName.contains('GOTV')) return 'CABLE_PAY';
    if (itemCode.startsWith('UB') || billerName.contains('ELECTRIC') || billerName.contains('POWER')) return 'UTILITY_BILL';
    if (itemCode.startsWith('IS') || billerName.contains('INTERNET') || billerName.contains('SMILE') || billerName.contains('SPECTRANET')) return 'INTERNET_SERVICE';
    if (itemCode.startsWith('SP') || billerName.contains('SCHOOL') || billerName.contains('EXAM') || billerName.contains('JAMB') || billerName.contains('WAEC')) return 'SCHOOL_FEES';
    if (itemCode.startsWith('RI') || billerName.contains('RELIGIOUS') || billerName.contains('CHURCH') || billerName.contains('MOSQUE')) return 'RELIGIOUS_INSTITUTIONS';
    if (itemCode.startsWith('BT') || billerName.contains('BETTING') || billerName.contains('BET9JA') || billerName.contains('SPORTYBET')) return 'BETTING';
    if (itemCode.startsWith('TP') || itemCode.startsWith('TX') || billerName.contains('TAX')) return 'TAX_PAYMENT';
    if (itemCode.startsWith('OT') || billerName.contains('GOVERNMENT') || billerName.contains('PHCN')) return 'GOVERNMENT_PAYMENT';
    if (itemCode.startsWith('TL') || billerName.contains('LOGISTICS')) return 'LOGISTICS';
    if (itemCode.startsWith('DP') || billerName.contains('DEALER')) return 'DEALERS';
    
    return null;
  }

  void _selectCategory(String? categoryId, String? exactName) {
    setState(() {
      if (_selectedCategory == categoryId && exactName == null) {
        _selectedCategory = null;
        _searchController.clear();
      } else {
        _selectedCategory = categoryId;
        if (exactName != null) {
          _searchController.text = exactName.split(' ')[0];
        }
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
          if (_selectedCategory != null || _searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _searchController.clear();
                  _filterBillers();
                });
              },
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = entry.value[index];
                      return _ServiceGridItem(
                        name: item['name'],
                        icon: item['icon'],
                        badge: item['badge'],
                        onTap: () => _selectCategory(item['id'], item['name']),
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
                            child: Icon(
                              _getIconForBiller(biller['biller_name']),
                              color: AppTheme.accentCyan,
                              size: 20,
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

  IconData _getIconForBiller(String? billerType) {
    if (billerType == null) return Icons.payment;
    final type = billerType.toUpperCase();
    if (type.contains('AIRTIME')) return Icons.phone_android;
    if (type.contains('DATA')) return Icons.wifi;
    if (type.contains('CABLE')) return Icons.tv;
    if (type.contains('UTILITY')) return Icons.lightbulb_outline;
    if (type.contains('INTERNET')) return Icons.language;
    return Icons.payment;
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Center(
                  child: Icon(icon, color: AppTheme.accentCyan, size: 24),
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

class _BillPaymentSheet extends ConsumerStatefulWidget {
  final dynamic biller;
  const _BillPaymentSheet({required this.biller});

  @override
  ConsumerState<_BillPaymentSheet> createState() => _BillPaymentSheetState();
}

class _BillPaymentSheetState extends ConsumerState<_BillPaymentSheet> {
  final _customerController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _customerName;
  String? _validationError;

  final List<double> _quickAmounts = [100, 200, 500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    if (widget.biller['amount'] > 0) {
      _amountController.text = widget.biller['amount'].toString();
    }
  }

  Future<void> _validate() async {
    if (_customerController.text.isEmpty) return;
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

    final profile = ref.read(profileProvider);
    final wallet = profile.user?['wallet'];
    final balance = (wallet?['balance'] ?? 0).toDouble();

    if (balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient wallet balance'), backgroundColor: AppTheme.primaryRed),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await BillPaymentService.payBill(
        amount: amount,
        type: widget.biller['biller_name'],
        customer: _customerController.text,
        country: widget.biller['country'],
        billerName: widget.biller['name'],
      );
      
      if (mounted) {
        Navigator.pop(context); // Close sheet
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
    final isAirtime = widget.biller['biller_name'].toString().toUpperCase().contains('AIRTIME');
    final isData = widget.biller['biller_name'].toString().toUpperCase().contains('DATA');
    final showGrid = isAirtime || isData;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.biller['name'], style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(widget.biller['biller_name'] ?? 'Bill Payment', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.accentCyan.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(_getIconForSheet(widget.biller['biller_name']), color: AppTheme.accentCyan),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _customerController,
              style: const TextStyle(color: Colors.white),
              onChanged: (v) {
                if (v.length > 5 && (isAirtime || isData)) {
                   // Auto-validate or similar? Maybe just leave manual
                }
              },
              decoration: InputDecoration(
                labelText: _getLabelForBiller(),
                hintText: _getHintForBiller(),
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle, color: AppTheme.accentCyan),
                  onPressed: _validate,
                ),
              ),
            ),
            if (_isLoading && _customerName == null) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator(color: AppTheme.accentCyan)),
            if (_validationError != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_validationError!, style: const TextStyle(color: AppTheme.primaryRed, fontSize: 12))),
            if (_customerName != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Verified: $_customerName', style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold))),
            
            const SizedBox(height: 24),
            Text('Select Amount', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (showGrid) ...[
              GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
                itemCount: _quickAmounts.length,
                itemBuilder: (context, index) {
                  final amount = _quickAmounts[index];
                  final isSelected = _amountController.text == amount.toString();
                  return GestureDetector(
                    onTap: () => setState(() => _amountController.text = amount.toString()),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.accentCyan.withOpacity(0.2) : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppTheme.accentCyan : Colors.white10),
                      ),
                      child: Center(
                        child: Text(
                          '₦${amount.toInt()}',
                          style: TextStyle(color: isSelected ? AppTheme.accentCyan : Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            
            TextField(
              controller: _amountController,
              readOnly: widget.biller['amount'] > 0,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Manual Amount',
                prefixText: '₦ ',
                prefixStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: AppTheme.surfaceColor,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text('Pay Bill Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLabelForBiller() {
    final type = widget.biller['biller_name'].toString().toUpperCase();
    if (type.contains('AIRTIME') || type.contains('DATA')) return 'Phone Number';
    if (type.contains('CABLE') || type.contains('DSTV') || type.contains('GOTV')) return 'Smartcard Number';
    if (type.contains('UTILITY') || type.contains('ELECTRIC') || type.contains('POWER')) return 'Meter Number';
    if (type.contains('BETTING')) return 'User/Account ID';
    if (type.contains('INTERNET')) return 'Account ID';
    return widget.biller['label_name'] ?? 'Beneficiary ID';
  }

  String _getHintForBiller() {
    final type = widget.biller['biller_name'].toString().toUpperCase();
    if (type.contains('AIRTIME') || type.contains('DATA')) return 'e.g. 08012345678';
    if (type.contains('CABLE')) return 'e.g. 1234567890';
    if (type.contains('UTILITY')) return 'e.g. 010123456789';
    return 'Enter ID here';
  }

  IconData _getIconForSheet(String? billerType) {
    if (billerType == null) return Icons.payment;
    final type = billerType.toUpperCase();
    if (type.contains('AIRTIME')) return Icons.phone_android;
    if (type.contains('DATA')) return Icons.wifi;
    if (type.contains('CABLE')) return Icons.tv;
    if (type.contains('UTILITY') || type.contains('ELECTRIC')) return Icons.lightbulb_outline;
    if (type.contains('BETTING')) return Icons.sports_soccer_outlined;
    if (type.contains('INTERNET')) return Icons.language;
    return Icons.payment;
  }
}
