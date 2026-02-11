import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/features/business/business_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';

class FleetOnboardingScreen extends ConsumerStatefulWidget {
  const FleetOnboardingScreen({super.key});

  @override
  ConsumerState<FleetOnboardingScreen> createState() => _FleetOnboardingScreenState();
}

class _FleetOnboardingScreenState extends ConsumerState<FleetOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  
  String _selectedVehicleType = 'bike';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _licenseController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(businessProvider.notifier).onboardRider({
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'phone': _phoneController.text,
        'license_number': _licenseController.text,
        'vehicle_type': _selectedVehicleType,
        'vehicle_plate_number': _plateController.text,
      });

      if (success && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Rider Onboarded'),
            content: Text('${_nameController.text} has been successfully added to your fleet.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                child: const Text('Great'),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(businessProvider).error ?? 'Failed to onboard rider'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessState = ref.watch(businessProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Onboard New Rider',
          style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rider Details',
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the personal and professional details of the rider.',
                      style: GoogleFonts.outfit(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              _buildTextField('Full Name', _nameController, Icons.person_outline, 'John Doe'),
              _buildTextField('Email Address', _emailController, Icons.email_outlined, 'rider@fleet.com', isEmail: true),
              _buildTextField('Phone Number', _phoneController, Icons.phone_outlined, 'e.g. 020 7946 0000'),
              _buildTextField('Create Password', _passwordController, Icons.lock_outline, 'Minimum 8 characters', isPassword: true),
              
              const SizedBox(height: 24),
              Text(
                'Vehicle Information',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 16),
              
              _buildTextField('Driver\'s License Number', _licenseController, Icons.badge_outlined, 'e.g. 12345678'),
              _buildVehicleTypeSelector(),
              _buildTextField('Vehicle Plate Number', _plateController, Icons.pin_outlined, 'e.g. ABC-123-XY'),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: businessState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: businessState.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Onboard Rider', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, String hint, {bool isEmail = false, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          if (isEmail && !value.contains('@')) return 'Invalid email';
          if (isPassword && value.length < 8) return 'Password must be at least 8 characters';
          return null;
        },
      ),
    );
  }

  Widget _buildVehicleTypeSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vehicle Type', style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedVehicleType,
                isExpanded: true,
                items: ['bike', 'car', 'van', 'truck'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.toUpperCase()));
                }).toList(),
                onChanged: (val) => setState(() => _selectedVehicleType = val!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
