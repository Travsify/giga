import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/features/tracking/rider_stats_service.dart';
import 'package:flota_mobile/core/api_client.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:flota_mobile/features/wallet/wallet_provider.dart';
import 'package:flota_mobile/features/wallet/withdrawal_screen.dart';

// 1. MODELS & PROVIDERS

class BankAccount {
  final String id;
  final String accountName;
  final String accountNumber;
  final String bankName;
  final String gatewayType;
  final bool isActive;

  BankAccount({
    required this.id,
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
    required this.gatewayType,
    required this.isActive,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
    id: json['id'].toString(),
    accountName: json['account_name'],
    accountNumber: json['account_number'],
    bankName: json['bank_name'],
    gatewayType: json['gateway_type'],
    isActive: json['is_active'] == 1,
  );
}

final bankAccountsProvider = FutureProvider<List<BankAccount>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.dio.get('rider/banks');
    final List data = response.data['data'] ?? [];
    return data.map((b) => BankAccount.fromJson(b)).toList();
  } catch (e) {
    return [];
  }
});

// 2. MAIN HUB SCREEN

class RiderEarningsScreen extends ConsumerStatefulWidget {
  const RiderEarningsScreen({super.key});

  @override
  ConsumerState<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends ConsumerState<RiderEarningsScreen> {
  String _selectedPeriod = 'Today';
  bool _isWithdrawing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).fetchWalletData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(riderStatsProvider);
    final banksAsync = ref.watch(bankAccountsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Futuristic Gradient Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.surfaceColor,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildBalanceHeader(statsAsync),
            ),
          ),

          // Action Section: Withdrawal & Bank Management
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWithdrawSection(statsAsync, banksAsync),
                  const SizedBox(height: 32),
                  Text(
                    'INCOME INSIGHTS',
                    style: GoogleFonts.outfit(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPeriodSelector(),
                  const SizedBox(height: 16),
                  _buildWeeklyGraph(),
                  const SizedBox(height: 32),
                  Text(
                    'RECENT TRANSACTIONS',
                    style: GoogleFonts.outfit(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Transaction List
          _buildTransactionList(statsAsync),
        ],
      ),
    );
  }

  Widget _buildBalanceHeader(AsyncValue<RiderStats> statsAsync) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue,
            AppTheme.primaryBlue.withOpacity(0.6),
            AppTheme.backgroundColor,
          ],
        ),
      ),
      child: Center(
        child: statsAsync.when(
          data: (stats) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              const SizedBox(height: 48),
              Text(
                'AVAILABLE BALANCE',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, child) {
                  final walletState = ref.watch(walletProvider);
                  final currency = ref.read(authProvider).currencySymbol;
                  return Text(
                    '$currency${walletState.balance.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
                  );
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, color: AppTheme.successGreen, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '+12.5% from last week',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const CircularProgressIndicator(color: Colors.white),
          error: (e, _) => const Icon(Icons.error_outline, color: Colors.white, size: 48),
        ),
      ),
    );
  }

  Widget _buildWithdrawSection(AsyncValue<RiderStats> statsAsync, AsyncValue<List<BankAccount>> banksAsync) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderBlue),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payout Destination', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    banksAsync.when(
                      data: (banks) => Text(
                        banks.isEmpty ? 'No Bank Linked' : '${banks[0].bankName} •••• ${banks[0].accountNumber.substring(banks[0].accountNumber.length.clamp(4, 100) - 4)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      loading: () => const Text('Loading...', style: TextStyle(color: Colors.white54)),
                      error: (_, __) => const Text('Error', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showAddBankSheet(),
                child: const Text('MANAGE', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isWithdrawing ? null : () => _handleWithdrawal(statsAsync),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isWithdrawing 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('INSTANT WITHDRAWAL', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['Daily', 'Weekly', 'Monthly', 'Annual'].map((period) {
          final isSelected = _selectedPeriod == period;
          return GestureDetector(
            onTap: () => setState(() => _selectedPeriod = period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppTheme.primaryBlue : AppTheme.borderBlue),
              ),
              child: Text(
                period,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeeklyGraph() {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderBlue),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [20, 45, 30, 60, 85, 40, 55].map((height) => Container(
          width: 30,
          height: height.toDouble(),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [AppTheme.primaryBlue, AppTheme.accentCyan],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildTransactionList(AsyncValue<RiderStats> statsAsync) {
    final walletState = ref.watch(walletProvider);
    final transactions = walletState.transactions;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      sliver: transactions.isEmpty && !walletState.isLoading
          ? SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('No recent payouts yet.', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5))),
                ),
              ),
            )
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tx = transactions[index];
                  final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
                  final date = tx['created_at'] is String 
                      ? DateFormat('MMM dd, yyyy').format(DateTime.parse(tx['created_at']))
                      : 'Recently';

                  return _TransactionItem(
                    label: tx['description'] ?? 'Delivery Payout',
                    date: date,
                    amount: '${ref.read(authProvider).currencySymbol}${amount.abs().toStringAsFixed(2)}',
                    isPositive: amount > 0,
                  );
                },
                childCount: transactions.length > 5 ? 5 : transactions.length,
              ),
            ),
    );
  }

  Future<void> _handleWithdrawal(AsyncValue<RiderStats> statsAsync) async {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawalScreen()));
  }

  void _showAddBankSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => const _AddBankSheet(),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String label;
  final String date;
  final String amount;
  final bool isPositive;

  const _TransactionItem({required this.label, required this.date, required this.amount, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
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
              color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isPositive ? Icons.add : Icons.remove, color: isPositive ? Colors.green : Colors.red, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isPositive ? AppTheme.successGreen : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddBankSheet extends ConsumerStatefulWidget {
  const _AddBankSheet();
  @override
  ConsumerState<_AddBankSheet> createState() => _AddBankSheetState();
}

class _AddBankSheetState extends ConsumerState<_AddBankSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _bankCodeController = TextEditingController(); // Stores selected bank code or sort code
  final _searchController = TextEditingController();
  
  bool _isLoading = false;
  bool _isResolving = false;
  bool _isFetchingBanks = false;
  String? _fetchError;
  List<dynamic> _banks = [];
  List<dynamic> _filteredBanks = [];
  Map<String, dynamic>? _selectedBank;
  late String _region;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _region = (auth.countryCode == 'NG' || auth.countryCode == 'AF') ? 'Africa' : 'UK/Intl';
    if (_region == 'Africa') {
      _fetchBanks();
    }
  }

  Future<void> _fetchBanks() async {
    setState(() {
      _isFetchingBanks = true;
      _fetchError = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.get('banks?country=NG'); 
      if (mounted) {
        setState(() {
          _banks = response.data['data'] ?? [];
          _filteredBanks = _banks;
          _isFetchingBanks = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching banks: $e');
      if (mounted) {
        setState(() {
          _fetchError = 'Failed to load banks. Please check your connection.';
          _isFetchingBanks = false;
        });
      }
    }
  }

  void _filterBanks(String query) {
    setState(() {
      _filteredBanks = _banks.where((b) => 
        (b['name'] as String).toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  Future<void> _resolveAccount() async {
    if (_numberController.text.length != 10 || _selectedBank == null) return;
    
    setState(() => _isResolving = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.get('banks/resolve', queryParameters: {
        'account_number': _numberController.text,
        'bank_code': _selectedBank!['code'],
      });
      
      if (mounted && response.data['status'] == 'success') {
        setState(() {
          _nameController.text = response.data['data']['account_name'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Resolve Error: $e');
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 32,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LINK BANK ACCOUNT', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Secure your payouts for ${_region == 'Africa' ? 'African' : 'Intl'} market.', style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 32),
              
              if (_region == 'Africa') ...[
                Text('Select Bank', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showBankPicker(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderBlue),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_selectedBank?['name'] ?? 'Choose your bank...', style: TextStyle(color: _selectedBank == null ? Colors.grey : Colors.white)),
                        const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryBlue),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _numberController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  onChanged: (v) {
                    if (v.length == 10) _resolveAccount();
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Account Number',
                    suffixIcon: _isResolving ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)) : null,
                  ),
                  validator: (v) => v!.length < 10 ? 'Invalid' : null,
                ),
              ] else ...[
                _buildField('Account Holder Name', _nameController, Icons.person_outline),
                const SizedBox(height: 16),
                _buildField('Sort Code (XX-XX-XX)', _bankCodeController, Icons.vpn_key_outlined),
                const SizedBox(height: 16),
                _buildField('Account Number', _numberController, Icons.account_balance_wallet_outlined),
              ],

              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                readOnly: _region == 'Africa' && _isResolving,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Account Holder Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('SAVE ACCOUNT DETAILS', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showBankPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search bank...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                ),
                onChanged: (v) {
                  _filterBanks(v);
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isFetchingBanks 
                  ? const Center(child: CircularProgressIndicator())
                  : _fetchError != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppTheme.primaryRed),
                            const SizedBox(height: 16),
                            Text(_fetchError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                _fetchBanks();
                                setModalState(() {});
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredBanks.isEmpty
                      ? const Center(child: Text('No banks found', style: TextStyle(color: Colors.white70)))
                      : ListView.builder(
                          itemCount: _filteredBanks.length,
                          itemBuilder: (context, i) => ListTile(
                            title: Text(_filteredBanks[i]['name'], style: const TextStyle(color: Colors.white)),
                            onTap: () {
                              setState(() {
                                _selectedBank = _filteredBanks[i];
                                _resolveAccount();
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_region == 'Africa' && _selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a bank')));
      return;
    }
    
    setState(() => _isLoading = true);
    final api = ref.read(apiClientProvider);
    final sm = ScaffoldMessenger.of(context);
    try {
      final gateway = _region == 'Africa' ? 'flutterwave' : 'stripe';

      final response = await api.dio.post('rider/banks', data: {
        'account_name': _nameController.text,
        'account_number': _numberController.text,
        'bank_name': _region == 'Africa' ? _selectedBank!['name'] : 'UK/Intl Bank',
        'bank_code': _region == 'Africa' ? _selectedBank!['code'] : null,
        'sort_code': _region != 'Africa' ? _bankCodeController.text : null,
        'gateway_type': gateway,
      });

      if (response.data['status'] == 'success') {
        ref.invalidate(bankAccountsProvider);
        if (mounted) Navigator.pop(context);
        sm.showSnackBar(const SnackBar(content: Text('Bank linked successfully!'), backgroundColor: AppTheme.successGreen));
      }
    } catch (e) {
      sm.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
