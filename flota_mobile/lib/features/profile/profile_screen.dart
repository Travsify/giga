import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/features/profile/profile_provider.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
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
            Builder(
              builder: (context) {
                final country = ref.read(authProvider).countryCode;
                final amount = (country == 'NG') ? 5000 : (country == 'GH' ? 500 : 10);
                return Text('Enter a friend\'s code to get ${ref.read(authProvider).currencySymbol}$amount credit instantly.');
              }
            ),
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
    final profileState = ref.watch(profileProvider);
    final user = profileState.user;
    final loyalty = profileState.loyalty;
    final authState = ref.watch(authProvider);


    if (profileState.isLoading && user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?['name']?.isNotEmpty == true 
                            ? user!['name'] 
                            : (user?['email']?.split('@')[0] ?? 'Complete Profile'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (profileState.subscription?['is_giga_plus'] == true)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.yellow[700],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'GIGA+',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        user?['email'] ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _showEditProfile,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white12,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Loyalty Card
                  _buildLoyaltyCard(loyalty),
                  const SizedBox(height: 24),

                  _sectionHeader('Membership & Account'),
                  _buildSavedPlaceTile(
                    'Giga+ Subscription',
                    profileState.subscription?['is_giga_plus'] == true 
                        ? 'Active Membership' 
                        : 'Explore Premium Benefits',
                    Icons.star_rounded,
                    onTap: () => context.push('/giga-plus'),
                  ),
                  _buildSavedPlaceTile(
                    ref.watch(authProvider).role == 'Business' ? 'Manage Business' : 'Join Giga for Business',
                    ref.watch(authProvider).role == 'Business' ? 'Corporate dashboard & billing' : 'Scale your logistics',
                    Icons.business_center_rounded,
                    onTap: () => context.push(ref.watch(authProvider).role == 'Business' ? '/business-dashboard' : '/business-enrollment'),
                  ),
                  const SizedBox(height: 12),
                  
                  _sectionHeader('Saved Places'),
                  _buildSavedPlaceTile(
                    'Home',
                    user?['home_address'] ?? 'Set Home Address',
                    Icons.home_outlined,
                    onTap: _showEditProfile,
                  ),
                  _buildSavedPlaceTile(
                    'Work',
                    user?['work_address'] ?? 'Set Work Address',
                    Icons.work_outline,
                    onTap: _showEditProfile,
                  ),
                  
                  const SizedBox(height: 24),
                  _sectionHeader('Referral Rewards'),
                  _buildReferralCard(loyalty),
                  
                  const SizedBox(height: 24),
                  _sectionHeader('Account & Legal'),
                  _buildSavedPlaceTile(
                    'Privacy Policy',
                    'How we handle your data',
                    Icons.privacy_tip_outlined,
                    onTap: () => context.push('/privacy'),
                  ),
                  _buildSavedPlaceTile(
                    'Terms & Conditions',
                    'Standard service agreement',
                    Icons.description_outlined,
                    onTap: () => context.push('/terms'),
                  ),
                  _buildSavedPlaceTile(
                    'Logout',
                    'Securely sign out of your account',
                    Icons.logout_rounded,
                    onTap: () => _showLogoutConfirmation(),
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Refreshing your profile...'), duration: Duration(seconds: 1)),
                        );
                        await ref.read(profileProvider.notifier).refresh();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        side: const BorderSide(color: AppTheme.primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _showReferralDialog,
                      child: const Text('Have a referral code?'),
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
                child: Builder(
                  builder: (context) {
                    final country = ref.watch(authProvider).countryCode;
                    final amount = (country == 'NG') ? 5000 : (country == 'GH' ? 500 : 10);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Refer & Earn ${ref.watch(authProvider).currencySymbol}$amount',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Text(
                          'Share your code with friends',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    );
                  }
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
