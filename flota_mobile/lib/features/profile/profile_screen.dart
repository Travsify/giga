import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/features/profile/profile_provider.dart';
import '../auth/auth_provider.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flota_mobile/shared/map_picker_screen.dart';
import 'package:flota_mobile/features/tracking/rider_stats_service.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:country_picker/country_picker.dart';
import 'verification_screen.dart';
import 'document_upload_screen.dart';
import 'package:image_picker/image_picker.dart';

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
  final _plateController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  bool _isVerifyingPlate = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _homeController.dispose();
    _workController.dispose();
    _plateController.dispose();
    _vehicleTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      // Navigate to upload screen using the existing flow
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentUploadScreen(documentType: 'passport_photo'),
          ),
        );
      }
    }
  }

  Future<void> _verifyPlate() async {
    final plate = _plateController.text.trim();
    if (plate.isEmpty) return;

    setState(() => _isVerifyingPlate = true);
    
    try {
      final country = ref.read(authProvider).countryCode ?? 'NG';
      final res = await ref.read(profileProvider.notifier).verifyPlate(plate, country);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle Verified: ${res['data']['make']} ${res['data']['model']}'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification Failed: $e'), backgroundColor: AppTheme.primaryRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifyingPlate = false);
    }
  }

  void _showEditProfile() {
    final user = ref.read(profileProvider).user;
    final authState = ref.read(authProvider);
    final role = user?['role'] ?? authState.role ?? 'Customer';
    
    if (user != null) {
      _nameController.text = user['name'] ?? '';
      _phoneController.text = user['uk_phone'] ?? '';
      _homeController.text = user['home_address'] ?? '';
      _workController.text = user['work_address'] ?? '';
      _plateController.text = user['vehicle_plate_number'] ?? '';
      _vehicleTypeController.text = user['vehicle_type'] ?? '';
    }

    final _companyNameController = TextEditingController(text: user?['company_name'] ?? '');
    final _regNumberController = TextEditingController(text: user?['registration_number'] ?? '');

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
            IntlPhoneField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_android),
                hintText: 'Enter phone number',
              ),
              initialCountryCode: authState.countryCode ?? 'NG',
              onChanged: (phone) {
                // _phoneController is already updated by the widget
              },
            ),
            const SizedBox(height: 16),
            GooglePlaceAutoCompleteTextField(
              googleAPIKey: "AIzaSyDVqP4CjWp_fcFim7d_E0kAL35Ie2gWMzE",
              textEditingController: _homeController,
              inputDecoration: InputDecoration(
                labelText: 'Home Address',
                prefixIcon: const Icon(Icons.home),
                hintText: 'Search home address',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map_outlined, color: AppTheme.primaryBlue),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapPickerScreen(title: 'Home Location')),
                    );
                    if (result != null && result is Map) {
                      setState(() => _homeController.text = result['address']);
                    }
                  },
                ),
              ),
              debounceTime: 600,
              isLatLngRequired: false,
              itemClick: (Prediction prediction) {
                _homeController.text = prediction.description ?? "";
                _homeController.selection = TextSelection.fromPosition(TextPosition(offset: prediction.description?.length ?? 0));
              },
            ),
            const SizedBox(height: 16),
            GooglePlaceAutoCompleteTextField(
              googleAPIKey: "AIzaSyDVqP4CjWp_fcFim7d_E0kAL35Ie2gWMzE",
              textEditingController: _workController,
              inputDecoration: InputDecoration(
                labelText: 'Work Address',
                prefixIcon: const Icon(Icons.work),
                hintText: 'Search work address',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map_outlined, color: AppTheme.primaryBlue),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapPickerScreen(title: 'Work Location')),
                    );
                    if (result != null && result is Map) {
                      setState(() => _workController.text = result['address']);
                    }
                  },
                ),
              ),
              debounceTime: 600,
              isLatLngRequired: false,
              itemClick: (Prediction prediction) {
                _workController.text = prediction.description ?? "";
                _workController.selection = TextSelection.fromPosition(TextPosition(offset: prediction.description?.length ?? 0));
              },
            ),
            const SizedBox(height: 16),
            if (role == 'Business') ...[
              TextField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _regNumberController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (role == 'Rider') ...[
              TextField(
                controller: _plateController,
                decoration: InputDecoration(
                  labelText: 'Vehicle Plate Number',
                  prefixIcon: const Icon(Icons.numbers),
                  hintText: 'e.g. ABJ-123',
                  suffixIcon: _isVerifyingPlate 
                    ? const SizedBox(height: 20, width: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                    : TextButton(
                        onPressed: _verifyPlate,
                        child: const Text('VERIFY', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vehicle Type', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Bike', 'Car', 'Truck', 'Sedan', 'SUV'].map((type) {
                      final bool isSelected = _vehicleTypeController.text == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            _vehicleTypeController.text = type;
                          });
                        },
                        selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: AppTheme.surfaceColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isSelected ? AppTheme.primaryBlue : AppTheme.borderBlue),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
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
                    vehiclePlate: _plateController.text,
                    vehicleType: _vehicleTypeController.text,
                    companyName: role == 'Business' ? _companyNameController.text : null,
                    registrationNumber: role == 'Business' ? _regNumberController.text : null,
                  );
                  // Update Rider specific info
                  final user = ref.read(profileProvider).user;
                  if (user != null && user['role'] == 'Rider') {
                     // We should add an endpoint for this or update the general profile one
                     // For now, let's assume we can pass it to the profile update
                  }
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
    final stats = ref.watch(riderStatsProvider).value;
    final authState = ref.watch(authProvider);
    
    final String role = user?['role'] ?? authState.role ?? 'Customer';
    final bool isRider = role == 'Rider';
    final bool isBusiness = role == 'Business';
    final bool isNG = authState.countryCode == 'NG';
    final bool isOnline = user?['is_online'] == true;

    if (profileState.isLoading && user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final rider = user?['rider'];

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
                        GestureDetector(
                          onTap: _pickProfileImage,
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isOnline ? Colors.greenAccent : Colors.white24, width: 3),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white10,
                                  backgroundImage: user?['avatar_url'] != null ? NetworkImage(user!['avatar_url']) : null,
                                  child: user?['avatar_url'] == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
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
                            if (rider?['verification_status'] == 'verified') ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.verified, color: Colors.amber, size: 22),
                            ],
                          ],
                        ),
                        Text(
                          rider?['verification_status'] == 'verified' 
                            ? 'Verified Giga Partner' 
                            : (isRider ? 'Pending Verification' : (isBusiness ? 'Verified Business' : 'Giga Member')),
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
                  // 2. ACTIVITY PILLARS (Rider Only)
                  if (isRider) ...[
                    Row(
                      children: [
                        _buildPillar('Rating', stats?.rating.toStringAsFixed(1) ?? "5.0", Icons.star_rounded, Colors.orange),
                        const SizedBox(width: 12),
                        _buildPillar('Deliveries', '${stats?.totalJobsCompleted ?? 0}', Icons.local_shipping_rounded, AppTheme.accentCyan),
                        const SizedBox(width: 12),
                        _buildPillar('On-Time', '${stats?.onTimeRate ?? 100}%', Icons.timer_rounded, AppTheme.successGreen),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],

                  // 3. VEHICLE ID CARD (Rider Only)
                  if (isRider) ...[
                    _sectionHeader('Active Vehicle'),
                    _buildVehicleCard(rider),
                    const SizedBox(height: 32),
                  ],

                  // 4. VERIFICATION HUB (Rider Only)
                  if (isRider) ...[
                    _sectionHeader('Trust & Verification'),
                    _buildVerificationHub(rider),
                    const SizedBox(height: 32),
                  ],

                  // 5. ACCOUNT ACTIONS
                  _sectionHeader('Account & Settings'),
                  _buildActionTile('Giga+ Membership', 'Manage your premium subscription', Icons.auto_awesome, () => context.push('/giga-plus')),
                  _buildActionTile('Referral Rewards', 'Earn ${authState.currencySymbol}${isNG ? '20,000' : '10'} per referral', Icons.card_giftcard, _showReferralDialog),
                  _buildActionTile('Payout Settings', 'Bank transfers & wallet', Icons.account_balance_wallet_outlined, () => context.push('/wallet')),
                  _buildActionTile('Help & Support', '24/7 Rider support', Icons.help_outline_rounded, () {}),
                  const SizedBox(height: 12),
                  _buildActionTile('Logout', 'Securely sign out', Icons.logout_rounded, _showLogoutConfirmation, isDestructive: true),
                  
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'App Version 1.2.5 (${authState.countryCode ?? 'UK'}-PRO)',
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
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderBlue),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic>? rider) {
    final bool hasVehicle = (rider?['has_vehicle'] as bool?) ?? false;
    
    if (!hasVehicle) {
      return GestureDetector(
        onTap: _showEditProfile,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderBlue, style: BorderStyle.solid),
          ),
          child: Column(
            children: [
              Icon(Icons.add_circle_outline, color: AppTheme.primaryBlue, size: 40),
              const SizedBox(height: 12),
              Text(
                'Add Your Vehicle',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Register your vehicle to start receiving jobs.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

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
                    'Active Vehicle',
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
              rider?['vehicle_plate_number'] ?? 'ACTIVE VEHICLE',
              style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                rider?['verification_status'] == 'verified' ? Icons.verified : Icons.error_outline, 
                color: rider?['verification_status'] == 'verified' ? Colors.greenAccent : Colors.orangeAccent, 
                size: 14
              ),
              const SizedBox(width: 6),
              Text(
                rider?['verification_status'] == 'verified' ? 'Documents Verified' : 'Pending Verification', 
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationHub(Map<String, dynamic>? rider) {
    final String status = rider?['verification_status'] ?? 'pending';
    final bool isVerified = status == 'verified';
    final bool hasLicense = rider?['driver_license_path'] != null;
    final bool hasRegistration = rider?['vehicle_registration_path'] != null;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderBlue),
      ),
      child: Column(
        children: [
          _buildHubItem(
            'Vehicle Registration', 
            hasRegistration ? 'Submitted' : 'Not Submitted', 
            hasRegistration,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VerificationScreen())),
          ),
          Divider(height: 1, indent: 50, color: AppTheme.borderBlue),
          _buildHubItem(
            'Driver License', 
            hasLicense ? 'On File' : 'Required', 
            hasLicense,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VerificationScreen())),
          ),
          Divider(height: 1, indent: 50, color: AppTheme.borderBlue),
          _buildHubItem(
            'Vehicle Photos', 
            (rider?['vehicle_front_path'] != null && rider?['vehicle_side_path'] != null) ? 'Submitted' : 'Pending', 
            rider?['vehicle_front_path'] != null && rider?['vehicle_side_path'] != null,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VerificationScreen())),
          ),
          Divider(height: 1, indent: 50, color: AppTheme.borderBlue),
          _buildHubItem(
            'Account Status', 
            isVerified ? 'Active Partner' : (status == 'submitted' ? 'Under Review' : 'Pending Verification'), 
            isVerified,
            isPending: status == 'submitted',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VerificationScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildHubItem(String title, String subtitle, bool isVerified, {required VoidCallback onTap, bool isPending = false}) {
    Color color = isVerified ? Colors.green : (isPending ? AppTheme.primaryBlue : Colors.orange);
    IconData icon = isVerified ? Icons.verified_user_rounded : (isPending ? Icons.hourglass_top_rounded : Icons.pending_rounded);

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: color)),
      trailing: Icon(Icons.chevron_right, size: 20, color: AppTheme.textSecondary),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderBlue),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isDestructive ? Colors.red : AppTheme.accentCyan),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDestructive ? Colors.red : Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        trailing: Icon(Icons.chevron_right, size: 20, color: AppTheme.textSecondary),
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


}
