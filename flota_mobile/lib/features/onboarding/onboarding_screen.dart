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
    
    // settings.get can return the raw list if already parsed by dio/json_serializable
    // or a string if hidden in a larger json blob.
    final dynamic slidesRaw = settings.get<dynamic>('onboarding_slides', []);

    if (slidesRaw is List && slidesRaw.isNotEmpty) {
       _slides = slidesRaw.map((e) => {
          'image': e['image']?.toString() ?? '',
          'title': e['title']?.toString() ?? '',
          'description': e['description']?.toString() ?? '',
        }).toList();
    } else if (slidesRaw is String && slidesRaw.isNotEmpty) {
      try {
        final List<dynamic> parsed = json.decode(slidesRaw);
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
          'image': 'assets/images/onboarding_welcome.png',
          'title': 'Welcome to Giga',
          'description': 'Your UK-wide logistics partner'
        },
        {
          'image': 'assets/images/onboarding_fast.png',
          'title': 'Fast & Reliable',
          'description': 'From bikes to trucks, we deliver it all'
        },
        {
          'image': 'assets/images/onboarding_track.png',
          'title': 'Track in Real-time',
          'description': 'Monitor your parcels live'
        },
        {
          'image': 'assets/images/onboarding_earn.png',
          'title': 'Earn with Giga',
          'description': 'Join our fleet and start earning'
        },
        {
          'image': 'assets/images/onboarding_ready.png',
          'title': 'Ready to move?',
          'description': "Let's go!"
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
                                      Image.asset('assets/images/onboarding_welcome.png', fit: BoxFit.contain),
                                  )
                                : Image.asset(imageUrl.isNotEmpty ? imageUrl : 'assets/images/onboarding_welcome.png', fit: BoxFit.contain),
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
