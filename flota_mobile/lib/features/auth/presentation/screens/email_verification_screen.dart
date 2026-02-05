import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/core/api_client.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final bool isPhone;
  final String? phoneNumber;
  final bool isLoginVerification; // New: flag to indicate if coming from login
  
  const EmailVerificationScreen({
    super.key, 
    this.isPhone = false, 
    this.phoneNumber,
    this.isLoginVerification = false,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  bool _isVerified = false;
  String? _errorMessage;

  static const _primaryBlue = Color(0xFF1A3B8C);
  static const _accentRed = Color(0xFFD32F2F);
  static const int _otpLength = 7; // Updated to 7 digits

  @override
  void initState() {
    super.initState();
    _sendVerificationCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    setState(() => _isResending = true);
    try {
      final api = ref.read(apiClientProvider);
      if (widget.isPhone && widget.phoneNumber != null) {
        await api.dio.post('phone/send-otp', data: {'phone': widget.phoneNumber});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('SMS code sent!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        await api.dio.post('email/send-verification');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('7-digit verification code sent to your email!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send code'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != _otpLength) {
      setState(() => _errorMessage = 'Please enter the complete $_otpLength-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      
      if (widget.isPhone) {
        await api.dio.post('phone/verify-otp', data: {
          'phone': widget.phoneNumber,
          'code': _codeController.text
        });
        await ref.read(authProvider.notifier).markAsVerified();
      } else {
        await api.dio.post('email/verify', data: {'code': _codeController.text});
        await ref.read(authProvider.notifier).markAsVerified();
      }
      
      setState(() {
        _isVerified = true;
        _isLoading = false;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        // Navigate based on user role
        final role = ref.read(authProvider).role;
        if (role == 'Rider') {
          context.go('/rider-dashboard');
        } else {
          context.go('/marketplace');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid or expired code. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerified) return _buildSuccessView();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_primaryBlue, Color(0xFF0D2555)],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),

              // Icon & Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    FadeInDown(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isPhone ? Icons.phone_android_rounded : Icons.mark_email_unread_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInDown(
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        widget.isPhone ? "Verify Your Phone" : "Verify Your Email",
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        widget.isPhone
                            ? "Enter the $_otpLength-digit code sent to ${widget.phoneNumber}"
                            : "Enter the $_otpLength-digit code sent to your email",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (widget.isLoginVerification)
                      FadeInDown(
                        delay: const Duration(milliseconds: 300),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Login verification required",
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // White Section
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
                    child: Column(
                      children: [
                        const SizedBox(height: 32),

                        // PIN Code Input - 7 digits
                        FadeInUp(
                          delay: const Duration(milliseconds: 300),
                          child: PinCodeTextField(
                            appContext: context,
                            controller: _codeController,
                            length: _otpLength,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            animationType: AnimationType.fade,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(12),
                              fieldHeight: 52,
                              fieldWidth: 42,
                              activeFillColor: Colors.white,
                              inactiveFillColor: const Color(0xFFF8FAFC),
                              selectedFillColor: _primaryBlue.withOpacity(0.05),
                              activeColor: _primaryBlue,
                              inactiveColor: const Color(0xFFE2E8F0),
                              selectedColor: _primaryBlue,
                              borderWidth: 1.5,
                            ),
                            enableActiveFill: true,
                            textStyle: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _primaryBlue,
                            ),
                            onCompleted: (value) => _verifyCode(),
                            onChanged: (value) => setState(() => _errorMessage = null),
                          ),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          FadeIn(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.outfit(color: Colors.red, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Verify Button
                        FadeInUp(
                          delay: const Duration(milliseconds: 400),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _verifyCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                      widget.isPhone ? "Verify Phone" : "Verify Email",
                                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Resend Link
                        FadeInUp(
                          delay: const Duration(milliseconds: 500),
                          child: TextButton(
                            onPressed: _isResending ? null : _sendVerificationCode,
                            child: _isResending
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: _primaryBlue),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Sending...', style: GoogleFonts.outfit(color: _primaryBlue)),
                                    ],
                                  )
                                : Text(
                                    "Didn't receive code? Resend",
                                    style: GoogleFonts.outfit(
                                      color: _primaryBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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

  Widget _buildSuccessView() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_primaryBlue, Color(0xFF0D2555)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeIn(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    widget.isPhone ? "Phone Verified!" : "Email Verified!",
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Welcome to Giga!\nRedirecting you...",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
