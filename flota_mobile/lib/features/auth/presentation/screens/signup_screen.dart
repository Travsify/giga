import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/api_client.dart';
import 'package:flota_mobile/core/settings_service.dart';
import 'package:flota_mobile/features/auth/domain/models/country_model.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final String? initialRole;
  const SignupScreen({super.key, this.initialRole});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _companyTypeController = TextEditingController();
  late String _selectedRole;
  bool _isPasswordVisible = false;
  
  // Verification States
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  bool _isVerifyingEmail = false;
  bool _isVerifyingPhone = false;
  String? _phoneVerificationId;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? 'Customer';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _companyNameController.dispose();
    _registrationNumberController.dispose();
    _companyTypeController.dispose();
    super.dispose();
  }

  // --- Email Verification Logic ---
  Future<void> _sendEmailOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter email first')));
      return;
    }

    setState(() => _isVerifyingEmail = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('signup/verify-email/send', data: {'email': email});
      if (mounted) _showOtpDialog(email, isEmail: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isVerifyingEmail = false);
    }
  }

  // _showEmailVerificationDialog is no longer needed as we use _showOtpDialog again

    // --- Phone Verification Logic ---
  Future<void> _sendPhoneOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter phone number first')));
      return;
    }

    setState(() => _isVerifyingPhone = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('phone/send-otp', data: {'phone': phone});
      if (mounted) _showOtpDialog(phone, isEmail: false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send SMS: $e')));
    } finally {
      if (mounted) setState(() => _isVerifyingPhone = false);
    }
  }

  void _showOtpDialog(String target, {required bool isEmail}) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Verify ${isEmail ? 'Email' : 'Phone'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the 6-digit code sent to $target'),
            const SizedBox(height: 20),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '000000', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.length != 6) return;
              
              try {
                final api = ref.read(apiClientProvider);
                if (isEmail) {
                  await api.dio.post('signup/verify-email/confirm', data: {
                    'email': target,
                    'code': code,
                  });
                  setState(() => _isEmailVerified = true);
                } else {
                   // Backend Phone Verify
                  await api.dio.post('phone/verify-otp', data: {
                    'phone': target,
                    'code': code,
                  });
                  setState(() => _isPhoneVerified = true);
                }
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid code')));
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {

    final settings = ref.read(settingsServiceProvider);
    final isPhoneEnabled = settings.get<bool>('auth_phone_enabled', true);
    final isEmailReq = settings.get<bool>('email_verification_enabled', true);
    final isPhoneReq = settings.get<bool>('phone_verification_enabled', true);

    if (_nameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        (isPhoneEnabled && _phoneController.text.isEmpty) || 
        _passwordController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
       return;
    }

    if ((isEmailReq && !_isEmailVerified) || (isPhoneEnabled && isPhoneReq && !_isPhoneVerified)) {
       String msg = 'Please verify your ';
       if (isEmailReq && !_isEmailVerified) msg += 'email';
       if (isEmailReq && !_isEmailVerified && isPhoneReq && !_isPhoneVerified) msg += ' and ';
       if (isPhoneReq && !_isPhoneVerified) msg += 'phone number';
       msg += '.';
       
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(msg), backgroundColor: Colors.orange)
       );
       return;
    }

    try {
      await ref.read(authProvider.notifier).register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _selectedRole,
        ukPhone: _phoneController.text.trim(),
        companyName: _selectedRole == 'Company' ? _companyNameController.text.trim() : null,
        registrationNumber: _selectedRole == 'Company' ? _registrationNumberController.text.trim() : null,
        companyType: _selectedRole == 'Company' ? _companyTypeController.text.trim() : null,
        countryCode: ref.read(settingsServiceProvider).currentCountry?.isoCode,
        currencyCode: ref.read(settingsServiceProvider).currentCountry?.currencyCode,
      );
      if (mounted) {
        // GoRouter will now handle redirection to /verify-email 
        // because AuthNotifier.register sets AuthStatus.authenticated 
        // but isEmailVerified will be false.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Premium Background Design
          const _BackgroundDecor(),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Back Button
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Brand Header (Smaller)
                  Center(
                    child: Column(
                      children: [
                        Image.asset('assets/images/logo.png', height: 40, width: 40),
                        const SizedBox(height: 8),
                        Text(
                          'GIGA',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryBlue,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Welcome Text
                  FadeInLeft(
                    duration: const Duration(milliseconds: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Account',
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Join the Giga network today',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black54.withOpacity(0.4),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Role Selection (Hidden as it's passed via route)
                  // FadeInUp(...)
                  
                  const SizedBox(height: 10),
                  
                  const SizedBox(height: 32),
                  
                  // Form Fields
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        // Country Selector
                        Consumer(
                          builder: (context, ref, _) {
                            final settings = ref.watch(settingsServiceProvider);
                            final countries = settings.supportedCountries;
                            final current = settings.currentCountry;

                            if (countries.isEmpty) return const SizedBox.shrink();

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4, bottom: 10),
                                    child: Text(
                                      'Country',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<Country>(
                                        value: current,
                                        isExpanded: true,
                                        hint: const Text("Select Country"),
                                        items: countries.map((c) {
                                          return DropdownMenuItem(
                                            value: c,
                                            child: Row(
                                              children: [
                                                Text(c.isoCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                const SizedBox(width: 10),
                                                Text(c.name),
                                                const Spacer(),
                                                Text(c.currencySymbol, style: const TextStyle(color: Colors.grey)),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            settings.setCountry(val);
                                            setState(() {}); // refresh UI if needed
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        _CustomTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'John Doe',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 24),
                        _CustomTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'your@email.com',
                          icon: Icons.alternate_email_rounded,
                          isVerified: _isEmailVerified,
                          onVerify: ref.watch(settingsServiceProvider).get<bool>('email_verification_enabled', true) ? _sendEmailOtp : null,
                          isLoading: _isVerifyingEmail,
                        ),
                        const SizedBox(height: 24),
                        if (ref.watch(settingsServiceProvider).get<bool>('auth_phone_enabled', true)) ...[
                          _CustomTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            hint: '+44 7000 000000',
                            icon: Icons.phone_android_rounded,
                            isVerified: _isPhoneVerified,
                            onVerify: ref.watch(settingsServiceProvider).get<bool>('phone_verification_enabled', true) ? _sendPhoneOtp : null,
                            isLoading: _isVerifyingPhone,
                          ),
                          const SizedBox(height: 24),
                        ],
                        _CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: '••••••••',
                          isPassword: true,
                          isPasswordVisible: _isPasswordVisible,
                          onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          icon: Icons.lock_outline_rounded,
                        ),
                        
                        if (_selectedRole == 'Company') ...[
                          const SizedBox(height: 32),
                          Text(
                            'Business Details',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _CustomTextField(
                            controller: _companyNameController,
                            label: 'Company Name',
                            hint: 'Giga Logistics Ltd',
                            icon: Icons.business_rounded,
                          ),
                          const SizedBox(height: 24),
                          _CustomTextField(
                            controller: _registrationNumberController,
                            label: 'Registration Number',
                            hint: 'UK12345678',
                            icon: Icons.assignment_rounded,
                          ),
                          const SizedBox(height: 24),
                          _CustomTextField(
                            controller: _companyTypeController,
                            label: 'Company Type',
                            hint: 'Courier / Freight / Last Mile',
                            icon: Icons.category_rounded,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Signup Button
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 10,
                          shadowColor: AppTheme.primaryBlue.withOpacity(0.4),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                            : const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Login Link
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: Center(
                      child: GestureDetector(
                        onTap: () => context.go('/login'),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 16, color: Colors.black54),
                            children: [
                              const TextSpan(text: "Already have an account? "),
                              TextSpan(
                                text: "Sign In",
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w900,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                   const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black38,
                size: 28,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryRed.withOpacity(0.06),
                  AppTheme.primaryRed.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool? isPasswordVisible;
  final VoidCallback? onToggleVisibility;
  final bool isVerified;
  final VoidCallback? onVerify;
  final bool isLoading;

  const _CustomTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.isPasswordVisible,
    this.onToggleVisibility,
    this.isVerified = false,
    this.onVerify,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !(isPasswordVisible ?? false),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.black.withOpacity(0.2)),
              prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: 22),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        (isPasswordVisible ?? false) ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: Colors.black26,
                        size: 20,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : (onVerify != null
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextButton(
                            onPressed: (isVerified || isLoading) ? null : onVerify,
                            style: TextButton.styleFrom(
                              backgroundColor: isVerified 
                                  ? Colors.green.withOpacity(0.1) 
                                  : AppTheme.primaryBlue.withOpacity(0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: isLoading
                                ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(
                                    isVerified ? 'VERIFIED' : 'VERIFY',
                                    style: TextStyle(
                                      color: isVerified ? Colors.green : AppTheme.primaryBlue,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                        )
                      : null),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }
}
