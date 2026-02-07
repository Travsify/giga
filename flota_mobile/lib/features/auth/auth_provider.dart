import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flota_mobile/features/auth/data/auth_repository.dart';
import 'package:flota_mobile/features/profile/profile_provider.dart';
import 'package:flota_mobile/features/wallet/wallet_provider.dart';
import 'package:flota_mobile/features/business/business_provider.dart';
import 'package:flota_mobile/features/marketplace/delivery_provider.dart';
import 'package:flota_mobile/features/promos/promo_provider.dart';

enum AuthStatus { authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final String? userEmail;
  final String? role;
  final String? userName;
  final String? token;
  final String? userId;
  final String? referralCode;
  final String? businessId;
  final bool isEmailVerified;
  final String? countryCode;
  final String? currencyCode;
  final String serviceMode; // 'delivery' or 'errand'

  AuthState({
    this.status = AuthStatus.unauthenticated,
    this.userEmail,
    this.role,
    this.userName,
    this.token,
    this.userId,
    this.referralCode,
    this.businessId,
    this.isEmailVerified = false,
    this.countryCode,
    this.currencyCode,
    this.serviceMode = 'delivery',
  });

  String get currencySymbol {
    switch(currencyCode) {
      case 'NGN': return '₦';
      case 'GHS': return '₵';
      case 'USD': return '\$';
      case 'GBP': default: return '£';
    }
  }

  AuthState copyWith({
    AuthStatus? status,
    String? userEmail,
    String? role,
    String? userName,
    String? token,
    String? userId,
    String? referralCode,
    String? businessId,
    bool? isEmailVerified,
    String? countryCode,
    String? currencyCode,
    String? serviceMode,
  }) {
    return AuthState(
      status: status ?? this.status,
      userEmail: userEmail ?? this.userEmail,
      role: role ?? this.role,
      userName: userName ?? this.userName,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      referralCode: referralCode ?? this.referralCode,
      businessId: businessId ?? this.businessId,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      countryCode: countryCode ?? this.countryCode,
      currencyCode: currencyCode ?? this.currencyCode,
      serviceMode: serviceMode ?? this.serviceMode,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;
  final _storage = const FlutterSecureStorage();

  AuthNotifier(this._repository, this._ref) : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token != null) {
        // In a real app, you'd verify the token or fetch user profile here
        final email = await _storage.read(key: 'user_email');
        final role = await _storage.read(key: 'user_role');
        final name = await _storage.read(key: 'user_name');
        final userId = await _storage.read(key: 'user_id');
        final referralCode = await _storage.read(key: 'user_referral_code');
        final businessId = await _storage.read(key: 'user_business_id');
        final countryCode = await _storage.read(key: 'user_country_code');
        final currencyCode = await _storage.read(key: 'user_currency_code');
        final isVerified = await _storage.read(key: 'is_email_verified') == 'true';
        
        state = state.copyWith(
          status: AuthStatus.authenticated,
          token: token,
          userEmail: email,
          role: role ?? 'Customer',
          userName: name,
          userId: userId,
          referralCode: referralCode,
          businessId: businessId,
          isEmailVerified: isVerified,
          countryCode: countryCode,
          currencyCode: currencyCode,
        );
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String login, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _repository.login(login, password);
      
      final token = response['token'];
      final user = response['user'];
      
      // Save session
      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'user_email', value: user['email']);
      await _storage.write(key: 'user_role', value: user['role'] ?? 'Customer');
      await _storage.write(key: 'user_name', value: user['name']);
      await _storage.write(key: 'user_id', value: user['id'].toString());
      await _storage.write(key: 'user_referral_code', value: user['referral_code']);
      await _storage.write(key: 'user_business_id', value: user['business_id']?.toString());
      await _storage.write(key: 'user_country_code', value: user['country_code']);
      await _storage.write(key: 'user_currency_code', value: user['currency_code']);

      // Store credentials for biometric login
      await _storage.write(key: 'saved_email', value: login);
      await _storage.write(key: 'saved_password', value: password);

      // Always require OTP verification on login
      await _storage.write(key: 'is_email_verified', value: 'false');

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        userEmail: user['email'],
        role: user['role'] ?? 'Customer',
        userName: user['name'],
        userId: user['id'].toString(),
        referralCode: user['referral_code'],
        businessId: user['business_id']?.toString(),
        isEmailVerified: false, // Force OTP on every login
        countryCode: user['country_code'],
        currencyCode: user['currency_code'],
      );
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated);
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password, String role, {
    String? ukPhone,
    String? companyName,
    String? registrationNumber,
    String? companyType,
    String? countryCode,
    String? currencyCode,
  }) async {
    // NOTE: Don't set AuthStatus.loading here - it triggers router redirect to /loading
    // The signup screen handles its own loading state via _isLoading
    try {
      final response = await _repository.register(
        name: name,
        email: email,
        password: password,
        role: role,
        ukPhone: ukPhone,
        companyName: companyName,
        registrationNumber: registrationNumber,
        companyType: companyType,
        countryCode: countryCode,
        currencyCode: currencyCode,
      );
      
      // DEBUG: Check for bypassed OTP
      if (response['debug_otp'] != null) {
        print('------------------------------------------------');
        print('🚨 DEBUG OTP RECEIVED: ${response['debug_otp']} 🚨');
        print('Use this code to verify email immediately.');
        print('------------------------------------------------');
      }

      final token = response['token'];
      final user = response['user'];

      // Save session
      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'user_email', value: user['email']);
      await _storage.write(key: 'user_role', value: user['role'] ?? 'Customer');
      await _storage.write(key: 'user_name', value: user['name']);
      await _storage.write(key: 'user_id', value: user['id'].toString());
      await _storage.write(key: 'user_business_id', value: user['business_id']?.toString());
      await _storage.write(key: 'user_country_code', value: user['country_code']);
      await _storage.write(key: 'user_currency_code', value: user['currency_code']);

      // Always require OTP verification on signup
      await _storage.write(key: 'is_email_verified', value: 'false');

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        userEmail: user['email'],
        role: user['role'] ?? 'Customer',
        userName: user['name'],
        userId: user['id'].toString(),
        businessId: user['business_id']?.toString(),
        isEmailVerified: false, // Force OTP on every signup
        countryCode: user['country_code'],
        currencyCode: user['currency_code'],
      );
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated);
      rethrow;
    }
  }

  Future<void> refreshUser() async {
    try {
      final response = await _repository.getProfile();
      final user = response['user'];
      
      final isVerified = user['email_verified_at'] != null;
      await _storage.write(key: 'is_email_verified', value: isVerified.toString());
      
      state = state.copyWith(
        role: user['role'] ?? 'Customer',
        userName: user['name'],
        isEmailVerified: isVerified,
      );
    } catch (e) {
      // If refresh fails, keep current state or log out if unauthorized
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      // Don't delete saved_email/saved_password so biometrics keep working
      final savedEmail = await _storage.read(key: 'saved_email');
      final savedPassword = await _storage.read(key: 'saved_password');
      
      await _storage.deleteAll();
      
      if (savedEmail != null) await _storage.write(key: 'saved_email', value: savedEmail);
      if (savedPassword != null) await _storage.write(key: 'saved_password', value: savedPassword);
      
      // Invalidate all session-dependent providers
      _ref.invalidate(profileProvider);
      _ref.invalidate(walletProvider);
      _ref.invalidate(businessProvider);
      _ref.invalidate(deliveryProvider);
      _ref.invalidate(promoProvider);
      
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> markAsVerified() async {
    await _storage.write(key: 'is_verified', value: 'true');
    state = state.copyWith(isEmailVerified: true);
  }

  void toggleServiceMode() {
    final newMode = state.serviceMode == 'delivery' ? 'errand' : 'delivery';
    state = state.copyWith(serviceMode: newMode);
    _storage.write(key: 'service_mode', value: newMode);
  }

  void setServiceMode(String mode) {
    if (mode == 'delivery' || mode == 'errand') {
      state = state.copyWith(serviceMode: mode);
      _storage.write(key: 'service_mode', value: mode);
    }
  }

  Future<String?> getStoredEmail() => _storage.read(key: 'saved_email');
  Future<String?> getStoredPassword() => _storage.read(key: 'saved_password');
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository, ref);
});
