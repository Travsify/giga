import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/features/profile/profile_provider.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flota_mobile/shared/map_picker_screen.dart';
import 'package:flota_mobile/shared/address_autocomplete_field.dart';

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
  String? _selectedImagePath;

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
    setState(() {
      _selectedImagePath = null; // Reset image path when opening
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
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
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondary.withOpacity(0.3),
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
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                        backgroundImage: _selectedImagePath != null 
                          ? FileImage(File(_selectedImagePath!)) as ImageProvider
                          : (user?['profile_image'] != null 
                             ? NetworkImage(user!['profile_image']) as ImageProvider
                             : null),
                        child: _selectedImagePath == null && user?['profile_image'] == null
                            ? const Icon(Icons.person, size: 50, color: AppTheme.primaryBlue)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              setModalState(() {
                                _selectedImagePath = image.path;
                              });
                              setState(() {
                                _selectedImagePath = image.path;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'Enter your name',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final country = ref.watch(authProvider).countryCode;
                    String label = 'Phone Number';
                    String hint = 'Enter phone number';
                    
                    if (country == 'NG') {
                      label = 'NG Phone Number';
                      hint = '+234 ...';
                    } else if (country == 'GH') {
                      label = 'GH Phone Number';
                      hint = '+233 ...';
                    } else {
                      label = 'UK Phone Number';
                      hint = '+44 7...';
                    }

                    return TextField(
                      controller: _phoneController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: label,
                        prefixIcon: const Icon(Icons.phone_android),
                        hintText: hint,
                      ),
                      keyboardType: TextInputType.phone,
                    );
                  }
                ),
                const SizedBox(height: 16),
                AddressAutocompleteField(
                  controller: _homeController,
                  label: 'Home Address',
                  icon: Icons.home,
                  onMapPickerTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MapPickerScreen(title: 'Home Location'),
                      ),
                    );
                    if (result != null && result is Map) {
                      setModalState(() {
                        _homeController.text = result['address'];
                      });
                      setState(() {
                        _homeController.text = result['address'];
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                AddressAutocompleteField(
                  controller: _workController,
                  label: 'Work Address',
                  icon: Icons.work,
                  onMapPickerTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MapPickerScreen(title: 'Work Location'),
                      ),
                    );
                    if (result != null && result is Map) {
                      setModalState(() {
                        _workController.text = result['address'];
                      });
                      setState(() {
                        _workController.text = result['address'];
                      });
                    }
                  },
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
                        imagePath: _selectedImagePath,
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
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text('Logout', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        content: const Text('Are you sure you want to log out of Giga?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/welcome');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showReferralDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Have a Referral Code?', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (context) {
                final country = ref.read(authProvider).countryCode;
                final amount = (country == 'NG') ? 5000 : (country == 'GH' ? 500 : 10);
                return Text(
                  'Enter a friend\'s code to get ${ref.read(authProvider).currencySymbol}$amount credit instantly.',
                  style: const TextStyle(color: AppTheme.textSecondary),
                );
              }
            ),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'ENTER CODE',
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

    if (profileState.isLoading && user == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Giga Brand Aura Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
              ),
            ),
          ),
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.15),
                    AppTheme.primaryBlue.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryRed.withOpacity(0.1),
                    AppTheme.primaryRed.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          
          CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.8),
                      AppTheme.primaryBlue.withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white24,
                        backgroundImage: user?['profile_image'] != null 
                          ? NetworkImage(user!['profile_image'])
                          : null,
                        child: user?['profile_image'] == null
                          ? const Icon(Icons.person, size: 45, color: Colors.white)
                          : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?['name']?.isNotEmpty == true 
                            ? user!['name'] 
                            : (user?['email']?.split('@')[0] ?? 'Complete Profile'),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (profileState.subscription?['is_giga_plus'] == true)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentCyan,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'GIGA+',
                            style: TextStyle(
                              color: AppTheme.backgroundColor,
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
                    onTap: _showLogoutConfirmation,
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Refreshing...'), duration: Duration(seconds: 1)),
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
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildLoyaltyCard(Map<String, dynamic>? loyalty) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.2),
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
                const SizedBox(width: 8),
                const Text(
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildReferralCard(Map<String, dynamic>? loyalty) {
    final code = loyalty?['referral_code'] ?? 'GENERATING...';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.card_giftcard, color: AppTheme.primaryBlue),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
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
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20, color: AppTheme.textSecondary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied to clipboard')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, size: 20, color: AppTheme.textSecondary),
                      onPressed: () {
                        Share.share('Use my Giga code $code to get credit off your first delivery! Download now.');
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
              Container(width: 1, height: 30, color: AppTheme.primaryBlue.withOpacity(0.2)),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

