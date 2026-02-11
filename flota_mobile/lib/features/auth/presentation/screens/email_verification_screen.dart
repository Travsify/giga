import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/core/api_client.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final bool isPhone;
  final String? phoneNumber;
  final bool isLoginVerification;
  
  const EmailVerificationScreen({
    super.key, 
    this.isPhone = false, 
    this.phoneNumber,
    this.isLoginVerification = false,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> with TickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  bool _isVerified = false;
  String? _errorMessage;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  late AnimationController _shakeController;
  late AnimationController _pulseController;

  static const int _otpLength = 7;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _sendVerificationCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _countdownTimer?.cancel();
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _resendCountdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendVerificationCode() async {
    setState(() => _isResending = true);
    try {
      final api = ref.read(apiClientProvider);
      if (widget.isPhone && widget.phoneNumber != null) {
        await api.dio.post('phone/send-otp', data: {'phone': widget.phoneNumber});
      } else {
        await api.dio.post('email/send-verification');
      }
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(widget.isPhone ? 'SMS code sent!' : 'Verification code sent to your email!'),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send code: $e'),
            backgroundColor: AppTheme.primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _triggerShake() {
    _shakeController.forward().then((_) => _shakeController.reset());
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != _otpLength) {
      setState(() => _errorMessage = 'Enter the complete $_otpLength-digit code');
      _triggerShake();
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
      } else {
        await api.dio.post('email/verify', data: {'code': _codeController.text});
      }
      
      await ref.read(authProvider.notifier).markAsVerified();
      
      setState(() {
        _isVerified = true;
        _isLoading = false;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        final role = ref.read(authProvider).role;
        if (role == 'Rider') {
          context.go('/rider');
        } else if (role == 'Business' || role == 'Company') {
          context.go('/business');
        } else {
          context.go('/marketplace');
        }
      }
    } catch (e) {
      _triggerShake();
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1B263B),
              Color(0xFF0D1B2A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            ...List.generate(15, (index) => _buildParticle(index)),
            
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                          ),
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Animated Icon
                  FadeInDown(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseController.value * 0.05),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryRed.withOpacity(0.3),
                                  AppTheme.primaryBlue.withOpacity(0.3),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryRed.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.isPhone ? Icons.smartphone_rounded : Icons.mail_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
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

                  const SizedBox(height: 12),

                  // Subtitle
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        widget.isPhone
                            ? "We've sent a $_otpLength-digit code to\n${widget.phoneNumber}"
                            : "We've sent a $_otpLength-digit code to\nyour email address",
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: Colors.white60,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  if (widget.isLoginVerification)
                    FadeInDown(
                      delay: const Duration(milliseconds: 300),
                      child: Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.security, size: 16, color: AppTheme.primaryOrange),
                            const SizedBox(width: 8),
                            Text(
                              "Two-factor authentication",
                              style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.primaryOrange),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Card Section
                  Expanded(
                    child: FadeInUp(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: NotificationListener<OverscrollIndicatorNotification>(
                          onNotification: (overscroll) {
                            overscroll.disallowIndicator();
                            return true;
                          },
                          child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // PIN Input with shake animation
                              AnimatedBuilder(
                                animation: _shakeController,
                                builder: (context, child) {
                                  final shake = sin(_shakeController.value * pi * 4) * 8;
                                  return Transform.translate(
                                    offset: Offset(shake, 0),
                                    child: child,
                                  );
                                },
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    // Calculate available width for 7 items + spacing
                                    // 7 items, 6 spaces. Let's say spacing is roughly half item width
                                    // Total = 7w + 6(w/2) = 10w approx
                                    final itemWidth = (constraints.maxWidth - 32) / 8; // generous spacing
                                    
                                    return PinCodeTextField(
                                      appContext: context,
                                      controller: _codeController,
                                      length: _otpLength,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      animationType: AnimationType.scale,
                                      pinTheme: PinTheme(
                                        shape: PinCodeFieldShape.box,
                                        borderRadius: BorderRadius.circular(8),
                                        fieldHeight: itemWidth * 1.3,
                                        fieldWidth: itemWidth,
                                        activeFillColor: Colors.white.withOpacity(0.1),
                                        inactiveFillColor: Colors.white.withOpacity(0.05),
                                        selectedFillColor: AppTheme.primaryRed.withOpacity(0.15),
                                        activeColor: AppTheme.primaryRed,
                                        inactiveColor: Colors.white.withOpacity(0.2),
                                        selectedColor: AppTheme.primaryRed,
                                        borderWidth: 1.5,
                                      ),
                                      enableActiveFill: true,
                                      cursorColor: AppTheme.primaryRed,
                                      textStyle: GoogleFonts.robotoMono(
                                        fontSize: itemWidth * 0.5,
                                        fontWeight: FontWeight.bold, // Reduced boldness
                                        color: Colors.white,
                                      ),
                                      onCompleted: (value) => _verifyCode(),
                                      onChanged: (value) => setState(() => _errorMessage = null),
                                    );
                                  }
                                ),
                              ),

                              // Error Message
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                FadeIn(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryRed.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: AppTheme.primaryRed, size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: GoogleFonts.outfit(color: AppTheme.primaryRed, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 28),

                              // Verify Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _verifyCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryRed,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: AppTheme.primaryRed.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 8,
                                    shadowColor: AppTheme.primaryRed.withOpacity(0.4),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.verified_user, size: 20),
                                            const SizedBox(width: 10),
                                            Text(
                                              "Verify & Continue",
                                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Resend with countdown
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Didn't receive code? ",
                                    style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
                                  ),
                                  if (_resendCountdown > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${_resendCountdown}s',
                                        style: GoogleFonts.robotoMono(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else
                                    TextButton(
                                      onPressed: _isResending ? null : _sendVerificationCode,
                                      child: _isResending
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRed),
                                            )
                                          : Text(
                                              "Resend",
                                              style: GoogleFonts.outfit(
                                                color: AppTheme.primaryRed,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticle(int index) {
    final random = Random(index);
    final size = random.nextDouble() * 4 + 2;
    final left = random.nextDouble() * MediaQuery.of(context).size.width;
    final top = random.nextDouble() * MediaQuery.of(context).size.height * 0.7;
    final opacity = random.nextDouble() * 0.3 + 0.1;

    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, sin(_pulseController.value * 2 * pi + index) * 10),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: (index % 2 == 0 ? AppTheme.primaryRed : AppTheme.primaryBlue).withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuccessView() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.successGreen.withOpacity(0.2), const Color(0xFF0D1B2A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ZoomIn(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successGreen.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, size: 80, color: AppTheme.successGreen),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    widget.isPhone ? "Phone Verified!" : "Email Verified!",
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Welcome to Giga!\nPreparing your experience...",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white60,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const CircularProgressIndicator(
                    color: AppTheme.successGreen,
                    strokeWidth: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
