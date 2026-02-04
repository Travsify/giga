import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/features/profile/profile_provider.dart';
import '../auth/auth_provider.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flota_mobile/shared/map_picker_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _homeController = TextEditingController();
  final _workController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _homeController.dispose();
    _workController.dispose();
    super.dispose();
  }

  void _showEditProfile() {
    final user = ref.read(profileProvider).user;
    if (user != null) {
      _nameController.text = user['name'] ?? '';
      _phoneController.text = user['uk_phone'] ?? '';
      _homeController.text = user['home_address'] ?? '';
      _workController.text = user['work_address'] ?? '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Update Profile',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'Enter your name',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'UK Phone Number',
                prefixIcon: Icon(Icons.phone_android),
                hintText: '+44 7... ',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _homeController,
              decoration: InputDecoration(
                labelText: 'Home Address',
                prefixIcon: const Icon(Icons.home),
                hintText: 'Enter your home address',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map_outlined, color: AppTheme.primaryBlue),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MapPickerScreen(title: 'Home Location'),
                      ),
                    );
                    if (result != null && result is Map) {
                      setState(() {
                        _homeController.text = result['address'];
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _workController,
              decoration: InputDecoration(
                labelText: 'Work Address',
                prefixIcon: const Icon(Icons.work),
                hintText: 'Enter your work address',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map_outlined, color: AppTheme.primaryBlue),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MapPickerScreen(title: 'Work Location'),
                      ),
                    );
                    if (result != null && result is Map) {
                      setState(() {
                        _workController.text = result['address'];
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await ref.read(profileProvider.notifier).updateProfile(
                    name: _nameController.text,
                    ukPhone: _phoneController.text,
                    homeAddress: _homeController.text,
                    workAddress: _workController.text,
                  );
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of Giga?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/welcome');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showReferralDialog() {
    final referralCode = ref.read(profileProvider).loyalty?['referral_code'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Have a Referral Code?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter a friend\'s code to get ${ref.watch(authProvider).currencySymbol}10 credit instantly.'),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'ENTER CODE',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) async {
                try {
                  await ref.read(profileProvider.notifier).submitReferral(value);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Credit added successfully!')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileState = ref.watch(profileProvider);
    final user = profileState.user;
    final loyalty = profileState.loyalty;
    final stats = ref.watch(riderStatsProvider).value;

    if (profileState.isLoading && user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final rider = user?['rider'];
    final isOnline = user?['is_online'] == true;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // 1. MODERN HEADER (GLASSMORPHISM EFFECT)
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.primaryBlue,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                   // Gradient Background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryBlue, Color(0xFF001A4D)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Decorative Circles
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(width: 200, height: 200, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle)),
                  ),
                  
                  // Profile Content
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: isOnline ? Colors.greenAccent : Colors.white24, width: 3),
                              ),
                              child: const CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white10,
                                child: Icon(Icons.person, size: 50, color: Colors.white),
                              ),
                            ),
                            if (isOnline)
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.primaryBlue, width: 3),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user?['name'] ?? 'Complete Profile',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.verified, color: Colors.amber, size: 22),
                          ],
                        ),
                        Text(
                          'Verified Giga Partner',
                          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showEditProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.15),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: const Text('Edit Profile'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. ACTIVITY PILLARS
                  Row(
                    children: [
                      _buildPillar('Rating', '${stats?.rating.toStringAsFixed(1) ?? "5.0"}', Icons.star_rounded, Colors.orange),
                      const SizedBox(width: 12),
                      _buildPillar('Deliveries', '${stats?.totalJobsCompleted ?? "0"}', Icons.local_shipping_rounded, AppTheme.primaryBlue),
                      const SizedBox(width: 12),
                      _buildPillar('Tier', 'Level 1', Icons.workspace_premium_rounded, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 3. VEHICLE ID CARD
                  _sectionHeader('Active Vehicle'),
                  _buildVehicleCard(rider),
                  const SizedBox(height: 32),

                  // 4. VERIFICATION HUB
                  _sectionHeader('Trust & Verification'),
                  _buildVerificationHub(rider),
                  const SizedBox(height: 32),

                  // 5. ACCOUNT ACTIONS
                  _sectionHeader('Account & Settings'),
                  _buildActionTile('Giga+ Membership', 'Manage your premium subscription', Icons.auto_awesome, () => context.push('/giga-plus')),
                  _buildActionTile('Referral Rewards', 'Earn £10 per referral', Icons.card_giftcard, _showReferralDialog),
                  _buildActionTile('Payout Settings', 'Bank transfers & wallet', Icons.account_balance_wallet_outlined, () => context.push('/wallet')),
                  _buildActionTile('Help & Support', '24/7 Rider support', Icons.help_outline_rounded, () {}),
                  const SizedBox(height: 12),
                  _buildActionTile('Logout', 'Securely sign out', Icons.logout_rounded, _showLogoutConfirmation, isDestructive: true),
                  
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'App Version 1.2.5 (UK-PRO)',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillar(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic>? rider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1219),
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: const NetworkImage('https://www.transparenttextures.com/patterns/carbon-fibre.png'),
          opacity: 0.1,
          repeat: ImageRepeat.repeat,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rider?['vehicle_type']?.toUpperCase() ?? 'COURIER VEHICLE',
                    style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Standard Fleet',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Icon(Icons.directions_car_filled_rounded, color: Colors.white24, size: 40),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber[400],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Text(
              rider?['vehicle_plate_number'] ?? 'GIGA FLEET',
              style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
              const SizedBox(width: 6),
              Text('Documents Verified', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationHub(Map<String, dynamic>? rider) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildHubItem('Driving License', 'Expires 2028', true),
          const Divider(height: 1, indent: 50),
          _buildHubItem('Commercial Insurance', 'Verified', true),
          const Divider(height: 1, indent: 50),
          _buildHubItem('Background Check', 'Completed', true),
        ],
      ),
    );
  }

  Widget _buildHubItem(String title, String subtitle, bool isVerified) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.verified_user_rounded, color: Colors.green, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isDestructive ? Colors.red : AppTheme.primaryBlue),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDestructive ? Colors.red : AppTheme.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildLoyaltyCard(Map<String, dynamic>? loyalty) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Giga Points',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '${ref.watch(authProvider).currencySymbol}${loyalty?['loyalty_points'] ?? '0.00'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.stars, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Premium',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPlaceTile(String title, String subtitle, IconData icon, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.primaryColor, size: 20),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
        subtitle: Text(subtitle, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Icon(Icons.chevron_right, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3), size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildReferralCard(Map<String, dynamic>? loyalty) {
    final code = loyalty?['referral_code'] ?? 'GENERATING...';
    
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.card_giftcard, color: theme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Refer & Earn ${ref.watch(authProvider).currencySymbol}10',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Share your code with friends',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1219),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  code,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: theme.primaryColor,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied to clipboard')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, size: 20),
                      onPressed: () {
                        Share.share('Use my Giga code $code to get £10 off your first delivery! Download now.');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoItem(loyalty?['referral_count']?.toString() ?? '0', 'Referrals'),
              Container(width: 1, height: 30, color: Colors.grey[200]),
              _infoItem('${ref.watch(authProvider).currencySymbol}${loyalty?['referral_earnings'] ?? '0'}', 'Earned'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
