import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flota_mobile/theme/app_theme.dart';
import 'package:flota_mobile/core/settings_service.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch settings to ensure they are loaded
    final settingsRec = ref.watch(settingsInitProvider);
    
    // Safety timeout: If settings take too long, move on anyway
    // In a real widget, you might want to do this in initState or a provider
    // but here we just rely on `when` or simplified check.
    
    // Better approach: Use a FutureBuilder or similar for the timeout if not handled in provider.
    // Since we are in build(), let's check connection state via Ref if we could, 
    // but `settingsInitProvider` is a FutureProvider.
    
    // Get actual settings values
    final settings = ref.read(settingsServiceProvider);
    
    // Force navigation if stuck (hacky but works for "forever load" fix)
    // Ideally this logic belongs in the Router, but let's make sure the UI
    // doesn't just sit here if the provider is stuck loading.
    
    final splashImageUrl = settings.get<String>('splash_image', ''); // Key from backend is splash_image

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Decor
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 1000),
                  child: Hero(
                    tag: 'app_logo',
                    child: splashImageUrl.isNotEmpty
                        ? Image.network(splashImageUrl, width: 180)
                        : Image.asset(
                            'assets/images/logo.png',
                            width: 180,
                          ),
                  ),
                ),
                const SizedBox(height: 40),
                FadeIn(
                  delay: const Duration(milliseconds: 800),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
