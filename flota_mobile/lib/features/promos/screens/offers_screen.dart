import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:flota_mobile/features/promos/promo_provider.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class OffersScreen extends ConsumerStatefulWidget {
  const OffersScreen({super.key});

  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(promoProvider.notifier).fetchPromos());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    if (_codeController.text.isEmpty) return;
    
    final success = await ref.read(promoProvider.notifier).validateCode(_codeController.text.trim(), 100); // 100 dummy amount for check
    
    if (!mounted) return;
    
    if (success) {
      final result = ref.read(promoProvider).validationResult;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Code Applied! Check checkout to use it.'),
        backgroundColor: Colors.green,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ref.read(promoProvider).error ?? 'Invalid Code'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final referralCode = ref.watch(authProvider).referralCode;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Promotions', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryBlue,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'My Offers'),
            Tab(text: 'Refer & Earn'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOffersTab(),
          _buildReferralTab(referralCode ?? 'GIGA-USER'),
        ],
      ),
    );
  }

  Widget _buildOffersTab() {
     final promoState = ref.watch(promoProvider);
     
     if (promoState.isLoading) {
       return const Center(child: CircularProgressIndicator());
     }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      hintText: 'Enter Promo Code',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _validateCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply'),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Text('Available For You', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          if (promoState.activePromos.isEmpty)
             Center(child: Text("No active offers at the moment.", style: TextStyle(color: Colors.grey))),

          ...promoState.activePromos.map((promo) => 
            FadeInUp(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.white]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.percent, color: AppTheme.primaryBlue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(promo['code'], style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                          Text(promo['description'] ?? 'Discount', style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                         Clipboard.setData(ClipboardData(text: promo['code']));
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code Copied!')));
                      },
                    )
                  ],
                ),
              ),
            )
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildReferralTab(String referralCode) {
    final symbol = ref.watch(authProvider).currencySymbol;
    final amount = symbol == '₦' ? '4,100' : '2';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Image.asset('assets/images/user_location.png', height: 150), // Reusing existing asset
          const SizedBox(height: 24),
          Text(
            'Give $symbol$amount, Get $symbol$amount',
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 12),
          Text(
            'Invite your friends to Giga. They get $symbol$amount off their first delivery, and you get $symbol$amount credit when they complete it.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryBlue, width: 2, style: BorderStyle.solid),
               boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                Text('Your Referral Code', style: GoogleFonts.outfit(color: Colors.grey[500])),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      referralCode,
                      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppTheme.primaryBlue),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: referralCode));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
                      },
                    )
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Share functionality would go here
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing functionality mocked')));
              },
              icon: const Icon(Icons.share),
              label: const Text('Share Code'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
