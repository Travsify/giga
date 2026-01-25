import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/features/business/business_provider.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';

class BusinessEnrollmentScreen extends ConsumerStatefulWidget {
  const BusinessEnrollmentScreen({super.key});

  @override
  ConsumerState<BusinessEnrollmentScreen> createState() => _BusinessEnrollmentScreenState();
}

class _BusinessEnrollmentScreenState extends ConsumerState<BusinessEnrollmentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _crnController = TextEditingController();
  final TextEditingController _vatController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  
  String _selectedType = 'LTD';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _crnController.dispose();
    _vatController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(businessProvider.notifier).enroll({
        'name': _nameController.text,
        'company_type': _selectedType,
        'business_email': _emailController.text,
        'registration_number': _crnController.text,
        'vat_number': _vatController.text,
        'address': _addressController.text,
        'contact_phone': _phoneController.text,
        'website': _websiteController.text,
      });

      if (success && mounted) {
        await ref.read(authProvider.notifier).refreshUser();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Enrollment Submitted'),
            content: const Text(
              'Your business profile has been submitted for verification. '
              'You will receive a notification once our team reviews your details.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  context.go('/business-dashboard');
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(businessProvider).error ?? 'Enrollment failed')),
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
          'Giga for Business',
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
                      'UK Business Setup',
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upgrade your account to unlock bulk shipping, VAT invoicing, and credit lines.',
                      style: GoogleFonts.outfit(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Company Information'),
              _buildTextField('Legal Business Name', _nameController, Icons.business, 'Enter business name'),
              _buildTypeSelector(),
              _buildTextField('Business Email', _emailController, Icons.email_outlined, 'e.g. logistics@company.co.uk', isEmail: true),
              _buildTextField('Company Reg Number (CRN)', _crnController, Icons.numbers, 'e.g. 12345678'),
              _buildTextField('VAT Number (Optional)', _vatController, Icons.receipt_long, 'e.g. GB 123 4567 89'),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Contact & Verification'),
              _buildTextField('Business Address', _addressController, Icons.location_on_outlined, 'Full legal address'),
              _buildTextField('Contact Phone', _phoneController, Icons.phone_outlined, 'e.g. 020 7946 0000'),
              _buildTextField('Website', _websiteController, Icons.language_outlined, 'e.g. https://company.co.uk'),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: businessState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: businessState.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Submit for Verification', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, String hint, {bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
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
          if (value == null || value.isEmpty) {
            if (label.contains('Optional')) return null;
            return 'Please enter $label';
          }
          if (isEmail && !value.contains('@')) return 'Invalid email';
          return null;
        },
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Company Type', style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[700])),
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
                value: _selectedType,
                isExpanded: true,
                items: ['LTD', 'PLC', 'Sole Trader'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
