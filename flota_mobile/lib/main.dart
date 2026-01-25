import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flota_mobile/features/auth/auth_provider.dart';
import 'package:flota_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:flota_mobile/features/auth/presentation/screens/signup_screen.dart';
import 'package:flota_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flota_mobile/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:flota_mobile/features/marketplace/data/models/delivery_models.dart';
import 'package:flota_mobile/features/onboarding/onboarding_screen.dart';
import 'package:flota_mobile/features/onboarding/welcome_screen.dart';
import 'package:flota_mobile/features/splash/splash_screen.dart';
import 'package:flota_mobile/features/marketplace/home_screen.dart';
import 'package:flota_mobile/features/marketplace/delivery_request_screen.dart';
import 'package:flota_mobile/features/marketplace/search_screen.dart';
import 'package:flota_mobile/features/wallet/checkout_screen.dart';
import 'package:flota_mobile/features/notifications/notification_screen.dart';
import 'package:flota_mobile/features/orders/order_history_screen.dart';
import 'package:flota_mobile/features/wallet/withdrawal_screen.dart';
import 'package:flota_mobile/features/location/ulez_scanner_screen.dart';
import 'package:flota_mobile/features/delivery/locker_map_screen.dart';
import 'package:flota_mobile/features/sustainability/carbon_dashboard_screen.dart';
import 'package:flota_mobile/features/promos/screens/offers_screen.dart';
import 'package:flota_mobile/features/tracking/rider_dashboard.dart';
import 'package:flota_mobile/features/tracking/tracking_screen.dart';
import 'package:flota_mobile/features/tracking/enhanced_tracking_screen.dart';
import 'package:flota_mobile/features/delivery/multi_stop_screen.dart';
import 'package:flota_mobile/features/tracking/chat_screen.dart';
import 'package:flota_mobile/features/delivery/parcel_locker_screen.dart';
import 'package:flota_mobile/features/profile/profile_screen.dart';
import 'package:flota_mobile/features/profile/giga_plus_screen.dart';
import 'package:flota_mobile/features/wallet/wallet_screen.dart';
import 'package:flota_mobile/features/wallet/payment_methods_screen.dart';
import 'package:flota_mobile/features/wallet/help_support_screen.dart';
import 'package:flota_mobile/features/profile/privacy_policy_screen.dart';
import 'package:flota_mobile/features/profile/terms_conditions_screen.dart';
import 'package:flota_mobile/features/business/presentation/screens/business_enrollment_screen.dart';
import 'package:flota_mobile/features/business/presentation/screens/business_dashboard_screen.dart';
import 'package:flota_mobile/features/business/presentation/screens/bulk_booking_screen.dart';
import 'package:flota_mobile/features/business/presentation/screens/billing_screen.dart';
import 'package:flota_mobile/features/business/presentation/screens/team_management_screen.dart';
import 'package:flota_mobile/features/business/presentation/screens/api_key_screen.dart';
import 'package:flota_mobile/theme/app_theme.dart';


import 'package:flota_mobile/features/business/presentation/screens/business_dashboard_screen.dart';
import 'package:flota_mobile/features/business/presentation/screens/team_management_screen.dart';
import 'package:flota_mobile/features/business/presentation/screens/billing_screen.dart';
import 'package:flota_mobile/features/business/presentation/screens/bulk_shipping_screen.dart';

import 'firebase_options.dart';

import 'package:flota_mobile/core/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Run app immediately with cached/default data
  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
  
  // Initialize settings in background (or handle in Splash)
  // We'll move the maintenance check logic into the SplashScreen for better UX
}

class MaintenanceApp extends StatelessWidget {
  final String? message;
  const MaintenanceApp({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.build_rounded, size: 64, color: Colors.orange),
                const SizedBox(height: 24),
                Text(
                  "Under Maintenance",
                   style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  message ?? "We are currently performing scheduled maintenance. Please check back later.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
      final isRegistering = state.matchedLocation.startsWith('/register');
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isSplash = state.matchedLocation == '/splash';
      final isForgotPassword = state.matchedLocation == '/forgot-password';

      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isAuthenticating = authState.status == AuthStatus.loading;
      final isVerified = authState.isEmailVerified;

      // While checking auth status at splash, don't redirect yet
      if (isAuthenticating && isSplash) return null;

      if (!isAuthenticated) {
        // If not logged in and on a protected route, go to onboarding/welcome
        if (isLoggingIn || isRegistering || isOnboarding || isSplash || isForgotPassword) {
          // If on splash, move to onboarding (first launch)
          if (isSplash && !isAuthenticating) return '/onboarding';
          return null;
        }
        // DEFAULT for all other unauthenticated states
        return '/welcome';
      }

      // 1. If authenticated BUT NOT VERIFIED, force /verify-email
      if (!isVerified) {
        if (state.matchedLocation == '/verify-email') return null;
        return '/verify-email';
      }

      // 2. If authenticated AND VERIFIED, NEVER stay on auth/onboarding/splash/verify pages
      final isVerifyPage = state.matchedLocation == '/verify-email';
      if (isLoggingIn || isRegistering || isSplash || isOnboarding || isVerifyPage) {
        if (authState.role == 'Rider') return '/rider';
        if (authState.role == 'Business' || authState.role == 'Company') return '/business';
        return '/marketplace';
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
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register/:role',
        builder: (context, state) => SignupScreen(
          initialRole: state.pathParameters['role'],
        ),
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
        path: '/verify-email',
        builder: (context, state) {
          final isPhone = state.uri.queryParameters['isPhone'] == 'true';
          final phoneNumber = state.uri.queryParameters['phoneNumber'];
          return EmailVerificationScreen(isPhone: isPhone, phoneNumber: phoneNumber);
        },
      ),
      GoRoute(
        path: '/marketplace',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/business',
        builder: (context, state) => const BusinessDashboardScreen(),
        routes: [
          GoRoute(path: 'team', builder: (context, state) => const TeamManagementScreen()),
          GoRoute(path: 'billing', builder: (context, state) => const BillingScreen()),
          GoRoute(path: 'bulk-shipping', builder: (context, state) => const BulkShippingScreen()),
        ],
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/ulez',
        builder: (context, state) => const ULEZScannerScreen(),
      ),
      GoRoute(
        path: '/lockers',
        builder: (context, state) => const LockerMapScreen(),
      ),
      GoRoute(
        path: '/carbon',
        builder: (context, state) => const CarbonDashboardScreen(),
      ),
      GoRoute(
        path: '/promos',
        builder: (context, state) => const OffersScreen(),
      ),
      GoRoute(
        path: '/delivery-request',
        builder: (context, state) => DeliveryRequestScreen(
          initiallyScheduled: state.uri.queryParameters['scheduled'] == 'true',
        ),
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
        GoRoute(
          path: '/wallet',
          builder: (context, state) => const WalletScreen(),
        ),
        GoRoute(
          path: '/withdraw',
          builder: (context, state) => const WithdrawalScreen(),
        ),
        GoRoute(
          path: '/payment-methods',
          builder: (context, state) => const PaymentMethodsScreen(),
        ),
        GoRoute(
          path: '/support',
          builder: (context, state) => const HelpSupportScreen(),
        ),
        GoRoute(
          path: '/privacy',
          builder: (context, state) => const PrivacyPolicyScreen(),
        ),
        GoRoute(
          path: '/terms',
          builder: (context, state) => const TermsConditionsScreen(),
        ),
        GoRoute(
          path: '/business-enrollment',
          builder: (context, state) => const BusinessEnrollmentScreen(),
        ),
        GoRoute(
          path: '/business-dashboard',
          builder: (context, state) => const BusinessDashboardScreen(),
        ),
        GoRoute(
          path: '/bulk-booking',
          builder: (context, state) => const BulkBookingScreen(),
        ),
        GoRoute(
          path: '/billing',
          builder: (context, state) => const BillingScreen(),
        ),
        GoRoute(
          path: '/team',
          builder: (context, state) => const TeamManagementScreen(),
        ),
        GoRoute(
          path: '/api-keys',
          builder: (context, state) => const ApiKeyScreen(),
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
