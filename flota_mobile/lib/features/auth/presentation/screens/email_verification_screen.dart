import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flota_mobile/core/api_client.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final bool isPhone;
  final String? phoneNumber;
  const EmailVerificationScreen({super.key, this.isPhone = false, this.phoneNumber});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  bool _isVerified = false;
  String? _errorMessage;
  String? _phoneVerificationId;

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
         // Backend Phone OTP
         final response = await api.dio.post('phone/send-otp', data: {'phone': widget.phoneNumber});
         final debugCode = response.data['debug_code'];
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(debugCode != null ? 'DEBUG OTP: $debugCode' : 'SMS code sent!'), 
                backgroundColor: debugCode != null ? Colors.deepOrange : Colors.green
              ),
            );
         }
      } else {
        // Backend Email OTP
        final response = await api.dio.post('email/send-verification');
        final debugCode = response.data['debug_code'];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(debugCode != null ? 'DEBUG OTP: $debugCode' : 'Verification code sent to your email!'), 
              backgroundColor: debugCode != null ? Colors.blueGrey : Colors.green
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send code: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false); // Removed !isPhone check, now relevant for both
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      
      if (widget.isPhone) {
        // Backend Phone Verify
        await api.dio.post('phone/verify-otp', data: {
            'phone': widget.phoneNumber,
            'code': _codeController.text
        });
        await ref.read(authProvider.notifier).markAsVerified();
      } else {
        // Backend Email Verify
        await api.dio.post('email/verify', data: {'code': _codeController.text});
        await ref.read(authProvider.notifier).markAsVerified();
      }
      
      setState(() {
        _isVerified = true;
        _isLoading = false;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/marketplace');
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Header Icon
                FadeInDown(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryBlue.withOpacity(0.1), AppTheme.primaryBlue.withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.mark_email_unread_rounded, size: 60, color: AppTheme.primaryBlue),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title
                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    widget.isPhone ? 'Phone Verification' : 'Security Verification',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black87),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Subtitle
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    widget.isPhone 
                      ? 'We\'ve sent a 6-digit SMS code to ${widget.phoneNumber}.'
                      : 'We\'ve sent a 6-digit verification code to your email address.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // PIN Code Input
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: PinCodeTextField(
                    appContext: context,
                    controller: _codeController,
                    length: 6,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: 56,
                      fieldWidth: 48,
                      activeFillColor: Colors.white,
                      inactiveFillColor: const Color(0xFFF8FAFC),
                      selectedFillColor: AppTheme.primaryBlue.withOpacity(0.05),
                      activeColor: AppTheme.primaryBlue,
                      inactiveColor: const Color(0xFFE2E8F0),
                      selectedColor: AppTheme.primaryBlue,
                    ),
                    enableActiveFill: true,
                    onCompleted: (value) => _verifyCode(),
                    onChanged: (value) => setState(() => _errorMessage = null),
                  ),
                ),
                
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
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
                        backgroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 8,
                        shadowColor: AppTheme.primaryBlue.withOpacity(0.3),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                        : Text(widget.isPhone ? 'Verify Phone' : 'Verify Email', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue)),
                              const SizedBox(width: 8),
                              const Text('Sending...'),
                            ],
                          )
                        : Text(
                            'Didn\'t receive code? Resend',
                            style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600, fontSize: 15),
                          ),
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

  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: FadeIn(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, size: 80, color: Colors.green),
                ),
                const SizedBox(height: 30),
                Text(
                  widget.isPhone ? 'Phone Verified!' : 'Email Verified!',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isPhone 
                    ? 'Your phone number has been verified successfully.\nRedirecting you...'
                    : 'Your email has been verified successfully.\nRedirecting you...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 40),
                CircularProgressIndicator(color: AppTheme.primaryBlue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
