import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:flota_mobile/features/onboarding/onboarding_screen.dart';
import 'package:flota_mobile/features/onboarding/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    // Artificial delay to ensure splash is seen
    await Future.delayed(const Duration(seconds: 2));
    
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    
    if (!mounted) return;
    
    // Use GoRouter for consistent navigation
    // FORCE ONBOARDING FOR TESTING
    GoRouter.of(context).go('/onboarding');
    /*
    if (hasSeenOnboarding) {
      GoRouter.of(context).go('/welcome');
    } else {
      GoRouter.of(context).go('/onboarding');
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    // This screen shows briefly while navigating - match native splash
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/splash_branding.png',
          width: 250,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
