import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flota_mobile/features/auth/data/auth_repository.dart';

enum AuthStatus { authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final String? userEmail;
  final String? role;
  final String? userName;
  final String? token;

  AuthState({
    this.status = AuthStatus.unauthenticated,
    this.userEmail,
    this.role,
    this.userName,
    this.token,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? userEmail,
    String? role,
    String? userName,
    String? token,
  }) {
    return AuthState(
      status: status ?? this.status,
      userEmail: userEmail ?? this.userEmail,
      role: role ?? this.role,
      userName: userName ?? this.userName,
      token: token ?? this.token,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final _storage = const FlutterSecureStorage();

  AuthNotifier(this._repository) : super(AuthState()) {
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
        
        state = state.copyWith(
          status: AuthStatus.authenticated,
          token: token,
          userEmail: email,
          role: role ?? 'Customer',
          userName: name,
        );
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _repository.login(email, password);
      
      final token = response['token'];
      final user = response['user'];
      
      // Save session
      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'user_email', value: user['email']);
      await _storage.write(key: 'user_role', value: user['role'] ?? 'Customer');
      await _storage.write(key: 'user_name', value: user['name']);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        userEmail: user['email'],
        role: user['role'] ?? 'Customer',
        userName: user['name'],
      );
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated);
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password, String role) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _repository.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      
      final token = response['token'];
      final user = response['user'];

      // Save session
      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'user_email', value: user['email']);
      await _storage.write(key: 'user_role', value: user['role'] ?? 'Customer');
      await _storage.write(key: 'user_name', value: user['name']);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        token: token,
        userEmail: user['email'],
        role: user['role'] ?? 'Customer',
        userName: user['name'],
      );
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      await _storage.deleteAll();
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
