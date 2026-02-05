import 'package:flutter/material.dart';
import 'package:flota_mobile/features/auth/presentation/screens/login_screen.dart'; // Assume exists or will be created
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Fast & Reliable",
      description: "From bikes to trucks, we deliver it all across the UK.",
      icon: Icons.local_shipping_rounded,
    ),
    OnboardingData(
      title: "Welcome to Giga",
      description: "Your UK-wide logistics partner for seamless delivery.",
      icon: Icons.public,
    ),
    OnboardingData(
      title: "Track your parcels",
      description: "Real-time tracking for every mile of the journey.",
      icon: Icons.map_outlined,
    ),
    OnboardingData(
      title: "Earn with Giga",
      description: "Join the fleet and start earning today on your schedule.",
      icon: Icons.savings_outlined,
    ),
    OnboardingData(
      title: "Join the Fleet",
      description: "Register now and become a Giga Partner.",
      icon: Icons.group_add_rounded,
    ),
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to Login/Auth
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), // Placeholder
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Giga Logo (Small)
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 0),
              child: Text(
                'GIGA',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF003399),
                  letterSpacing: 2.0,
                ),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Footer: Indicators + Button
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                   // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFFD32F2F) // Red Active
                              : const Color(0xFFE0E0E0), // Grey Inactive
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Next Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F), // Giga Red
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? "Get Started" : "Next",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Image Placeholder (Circle with Icon)
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F8FF), // Light Blue tint
            shape: BoxShape.circle,
          ),
          child: Icon(
            data.icon,
            size: 120,
            color: const Color(0xFF003399),
          ),
        ),
        const SizedBox(height: 48),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF003399),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            data.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;

  OnboardingData({required this.title, required this.description, required this.icon});
}

class LoginScreen extends StatelessWidget {
    const LoginScreen({super.key});
    @override
    Widget build(BuildContext context) {
        // Temporary Stub
        return const Scaffold(body: Center(child: Text("Login Screen")));
    }
}
