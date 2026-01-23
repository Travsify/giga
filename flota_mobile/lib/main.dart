import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:flota_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:flota_mobile/features/auth/presentation/screens/signup_screen.dart';
import 'package:flota_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flota_mobile/features/marketplace/data/models/delivery_models.dart';
import 'package:flota_mobile/features/onboarding/onboarding_screen.dart';
import 'package:flota_mobile/features/splash/splash_screen.dart';
import 'package:flota_mobile/features/marketplace/home_screen.dart';
import 'package:flota_mobile/features/marketplace/delivery_request_screen.dart';
import 'package:flota_mobile/features/wallet/checkout_screen.dart';
import 'package:flota_mobile/features/tracking/rider_dashboard.dart';
import 'package:flota_mobile/features/tracking/tracking_screen.dart';
import 'package:flota_mobile/features/tracking/enhanced_tracking_screen.dart';
import 'package:flota_mobile/features/delivery/multi_stop_screen.dart';
import 'package:flota_mobile/features/tracking/chat_screen.dart';
import 'package:flota_mobile/features/delivery/parcel_locker_screen.dart';
import 'package:flota_mobile/features/profile/profile_screen.dart';
import 'package:flota_mobile/features/profile/giga_plus_screen.dart';
import 'package:flota_mobile/theme/app_theme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Requires google-services.json
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (previous, next) {
      if (previous?.status != next.status || previous?.role != next.role) {
        notifyListeners();
      }
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) => RouterNotifier(ref));

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isSplash = state.matchedLocation == '/splash';
      final isForgotPassword = state.matchedLocation == '/forgot-password';

      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isAuthenticating = authState.status == AuthStatus.loading;

      // While checking auth status at splash, don't redirect yet
      if (isAuthenticating && isSplash) return null;

      if (!isAuthenticated) {
        // If not logged in and on a protected route, go to onboarding (for first time) or login
        if (isLoggingIn || isRegistering || isOnboarding || isSplash || isForgotPassword) {
          // If on splash, move to onboarding
          if (isSplash && !isAuthenticating) return '/onboarding';
          return null;
        }
        return '/login';
      }

      // If authenticated, NEVER stay on auth/onboarding/splash pages
      if (isLoggingIn || isRegistering || isSplash || isOnboarding) {
        return authState.role == 'Rider' ? '/rider' : '/marketplace';
      }

      // If user is accessing wrong dashboard, move them
      if (state.matchedLocation == '/marketplace' && authState.role == 'Rider') {
        return '/rider';
      }
      if (state.matchedLocation == '/rider' && authState.role != 'Rider') {
        return '/marketplace';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/marketplace',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/delivery-request',
        builder: (context, state) => const DeliveryRequestScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => CheckoutScreen(
          deliveryRequest: state.extra as DeliveryRequest,
        ),
      ),
      GoRoute(
        path: '/rider',
        builder: (context, state) => const RiderDashboard(),
      ),
      GoRoute(
        path: '/tracking',
        builder: (context, state) => const TrackingScreen(),
      ),
      GoRoute(
        path: '/tracking/enhanced/:id',
        builder: (context, state) => EnhancedTrackingScreen(
          deliveryId: state.pathParameters['id'] ?? 'unknown',
        ),
      ),
      GoRoute(
        path: '/multi-stop',
        builder: (context, state) => const MultiStopScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => ChatScreen(
          deliveryId: state.pathParameters['id'] ?? 'unknown',
        ),
      ),
        GoRoute(
          path: '/parcel-locker',
          builder: (context, state) => const ParcelLockerScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/giga-plus',
          builder: (context, state) => const GigaPlusScreen(),
        ),
      ],
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Giga',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
