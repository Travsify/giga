import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flota_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 5 Onboarding Screens - Global Messaging
  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Welcome to Giga",
      subtitle: "Your global logistics partner",
      description: "Delivering across continents - from Lagos to London, we've got you covered.",
      icon: Icons.local_shipping_rounded,
      hasBlueHeader: true,
    ),
    OnboardingData(
      title: "Track your parcels",
      subtitle: "in real-time",
      description: "Know exactly where your package is, every step of the way.",
      icon: Icons.map_outlined,
      hasBlueHeader: true,
    ),
    OnboardingData(
      title: "Earn with Giga",
      subtitle: "Join our fleet and start earning today",
      description: "Whether you ride a bike, scooter, or drive a truck - earn on your schedule.",
      icon: Icons.savings_outlined,
      hasBlueHeader: true,
    ),
    OnboardingData(
      title: "Fast & Reliable",
      subtitle: "From bikes to trucks",
      description: "Multiple delivery options to suit every need and budget.",
      icon: Icons.speed_rounded,
      hasBlueHeader: false,
    ),
    OnboardingData(
      title: "Ready to move?",
      subtitle: "Let's go!",
      description: "Sign up now and experience seamless delivery.",
      icon: Icons.touch_app_rounded,
      hasBlueHeader: false,
      isLastPage: true,
    ),
  ];

  void _onNext() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Save onboarding completion
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _skip() async {
    // Save onboarding completion
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pages[_currentPage].hasBlueHeader 
          ? const Color(0xFF1A3B8C) 
          : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: _pages[_currentPage].hasBlueHeader 
                          ? Colors.white70 
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),

            // Page Content
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

            // Footer
            Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: _pages[_currentPage].hasBlueHeader
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      )
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                              ? const Color(0xFFD32F2F)
                              : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
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
    if (data.hasBlueHeader) {
      // Blue Header Layout (like reference images 1, 2, 3)
      return Column(
        children: [
          // Blue Section with Illustration
          Expanded(
            flex: 3,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (data.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      data.subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  // Illustration Container
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      data.icon,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // White Footer Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Text(
              data.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      );
    } else {
      // White Background Layout (like reference images 4, 5)
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo at top
            Text(
              'Giga',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A3B8C),
              ),
            ),
            const SizedBox(height: 32),
            // Title
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A3B8C),
              ),
            ),
            Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A3B8C),
              ),
            ),
            const SizedBox(height: 40),
            // Central Illustration
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                data.icon,
                size: 90,
                color: const Color(0xFF1A3B8C),
              ),
            ),
            const SizedBox(height: 24),
            // Delivery Icons Row (for last screens)
            if (data.isLastPage) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSmallIcon(Icons.inventory_2_outlined),
                  _buildSmallIcon(Icons.two_wheeler),
                  _buildSmallIcon(Icons.local_shipping),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Text(
              data.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSmallIcon(IconData icon) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 32,
        color: const Color(0xFFD32F2F),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final bool hasBlueHeader;
  final bool isLastPage;

  OnboardingData({
    required this.title,
    this.subtitle = "",
    required this.description,
    required this.icon,
    this.hasBlueHeader = true,
    this.isLastPage = false,
  });
}
