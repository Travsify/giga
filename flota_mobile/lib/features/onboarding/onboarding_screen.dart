import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flota_mobile/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<String> _onboardingImages = [
    "assets/images/onboarding_1.png",
    "assets/images/onboarding_2.png",
    "assets/images/onboarding_3.png",
    "assets/images/onboarding_4.png",
    "assets/images/onboarding_5.png",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Match onboarding image backgrounds
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _currentPage = value),
                itemCount: _onboardingImages.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () {
                    if (_currentPage < _onboardingImages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    } else {
                      context.go('/login');
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(40), // Give some breathing room
                    child: Image.asset(
                      _onboardingImages[index],
                      fit: BoxFit.contain, // Prevent overspilling
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
              
              // Skip button
              if (_currentPage < _onboardingImages.length - 1)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          "Skip",
                          style: GoogleFonts.outfit(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Navigation Dot Indicator
              Positioned(
                bottom: constraints.maxHeight * 0.15,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _onboardingImages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppTheme.primaryBlue : Colors.black12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // Interactive region for the last screen (Get Started)
              // This aligns with the visual layout of the final onboarding image
              if (_currentPage == _onboardingImages.length - 1)
                Positioned(
                  bottom: constraints.maxHeight * 0.05,
                  left: 20,
                  right: 20,
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => context.go('/register'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: AppTheme.primaryBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            "Create Account",
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(
                            "Sign In",
                            style: GoogleFonts.outfit(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
