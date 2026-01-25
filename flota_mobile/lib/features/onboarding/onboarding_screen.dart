import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/settings_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<Map<String, String>> _slides = [];

  @override
  void initState() {
    super.initState();
    _loadSlides();
  }

  void _loadSlides() {
    final settings = ref.read(settingsServiceProvider);
    final slidesJson = settings.get<String>('onboarding_slides', '');
    
    if (slidesJson.isNotEmpty) {
      try {
        final List<dynamic> parsed = json.decode(slidesJson);
        _slides = parsed.map((e) => {
          'image': e['image']?.toString() ?? '',
          'title': e['title']?.toString() ?? '',
          'description': e['description']?.toString() ?? '',
        }).toList();
      } catch (e) {
        print('Error parsing onboarding slides: $e');
      }
    }

    // Fallback if empty or valid
    if (_slides.isEmpty) {
      _slides = [
        {
          'image': 'assets/images/onboarding_1.png',
          'title': 'Fast Delivery',
          'description': 'Description 1'
        },
        {
          'image': 'assets/images/onboarding_2.png',
          'title': 'Track Live',
          'description': 'Description 2'
        },
        {
          'image': 'assets/images/onboarding_3.png',
          'title': 'Safe & Secure',
          'description': 'Description 3'
        },
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _currentPage = value),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  // Use SettingsService to resolve URL
                  final settings = ref.read(settingsServiceProvider);
                  final imageUrl = settings.getAssetUrl(slide['image'] ?? '');
                  
                  final isNetworkImage = imageUrl.startsWith('http');
                  
                  return GestureDetector(
                    onTap: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      } else {
                        context.go('/welcome');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: isNetworkImage
                                ? Image.network(imageUrl, fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => 
                                      Image.asset('assets/images/onboarding_1.png', fit: BoxFit.contain),
                                  )
                                : Image.asset(imageUrl.isNotEmpty ? imageUrl : 'assets/images/onboarding_1.png', fit: BoxFit.contain),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            slide['title'] ?? '',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide['description'] ?? '',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // Skip button
              if (_currentPage < _slides.length - 1)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextButton(
                        onPressed: () => context.go('/welcome'),
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
                    _slides.length,
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

              // Get Started Button (Last Slide)
              if (_currentPage == _slides.length - 1)
                Positioned(
                  bottom: constraints.maxHeight * 0.05,
                  left: 20,
                  right: 20,
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: ElevatedButton(
                      onPressed: () => context.go('/welcome'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        "Get Started",
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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
