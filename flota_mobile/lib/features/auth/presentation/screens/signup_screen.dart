import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final String? initialRole;

  const SignupScreen({super.key, this.initialRole});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  late String _selectedRole;
  String _selectedCountry = 'GB'; // Default to UK

  static const _primaryBlue = Color(0xFF1A3B8C);
  static const _accentRed = Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? 'Rider';
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Map frontend role names to backend validation values
      // Backend accepts: Customer, Rider, Company
      String roleForBackend = _selectedRole;
      if (_selectedRole == 'Business') roleForBackend = 'Company';
      if (_selectedRole == 'Individual') roleForBackend = 'Customer';
      
      final currencyCode = _selectedCountry == 'NG' ? 'NGN' : 'GBP';
      
      await ref.read(authProvider.notifier).register(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text.trim(),
            roleForBackend,
            ukPhone: _phoneController.text.trim(),
            countryCode: _selectedCountry,
            currencyCode: currencyCode,
          );

      if (mounted) {
        context.push('/verify-email');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_primaryBlue, Color(0xFF0D2555)],
            stops: [0.0, 0.35],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    Text(
                      "Giga",
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      "Create Account",
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Join Giga and start your journey",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // White Form Section
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Role Selector Cards
                          Text(
                            "I am a...",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildRoleCard("Rider", Icons.two_wheeler),
                              const SizedBox(width: 12),
                              _buildRoleCard("Business", Icons.business),
                              const SizedBox(width: 12),
                              _buildRoleCard("Individual", Icons.person),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Country Selector
                          _buildLabel("Select Your Country"),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildCountryCard('GB', '🇬🇧', 'UK', 'GBP'),
                              const SizedBox(width: 16),
                              _buildCountryCard('NG', '🇳🇬', 'Nigeria', 'NGN'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Name
                          _buildLabel("Full Name"),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            style: GoogleFonts.outfit(fontSize: 16, color: Colors.black87),
                            textCapitalization: TextCapitalization.words,
                            decoration: _buildInputDecoration("Enter your name", Icons.person_outline),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Name is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email
                          _buildLabel("Email"),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.outfit(fontSize: 16, color: Colors.black87),
                            decoration: _buildInputDecoration("Enter your email", Icons.email_outlined),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Email is required';
                              if (!value.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Phone
                          _buildLabel("Phone Number"),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.outfit(fontSize: 16, color: Colors.black87),
                            decoration: _buildInputDecoration("Enter phone number", Icons.phone_outlined).copyWith(
                              prefixIcon: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 90,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.phone_outlined, color: Colors.grey[500]),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedCountry == 'NG' ? '+234' : '+44',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(height: 20, width: 1, color: Colors.grey[300]),
                                  ],
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Phone is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _buildLabel("Password"),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: GoogleFonts.outfit(fontSize: 16, color: Colors.black87),
                            decoration: _buildInputDecoration("Create a password", Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: Colors.grey[500],
                                ),
                                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Password is required';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 32),

                          // Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                                shadowColor: _accentRed.withOpacity(0.4),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      "Create Account",
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Login Link
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: GoogleFonts.outfit(color: Colors.grey[600]),
                                ),
                                GestureDetector(
                                  onTap: () => context.push('/login'),
                                  child: Text(
                                    "Log In",
                                    style: GoogleFonts.outfit(
                                      color: _primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildRoleCard(String role, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? _primaryBlue : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? _primaryBlue : Colors.grey[200]!,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: _primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : _primaryBlue, size: 28),
              const SizedBox(height: 8),
              Text(
                role,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : _primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryCard(String code, String flag, String name, String currency) {
    final isSelected = _selectedCountry == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCountry = code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? _primaryBlue : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? _primaryBlue : Colors.grey[200]!,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: _primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                : null,
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : _primaryBlue,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : _primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currency,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white70 : _primaryBlue.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 16),
      prefixIcon: Icon(icon, color: _primaryBlue, size: 22),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}
