import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flota_mobile/core/api_client.dart';

class WalletState {
  final bool isLoading;
  final double balance;
  final List<Map<String, dynamic>> transactions;
  final String? error;
  final String currencyCode;

  WalletState({
    this.isLoading = false,
    this.balance = 0.0,
    this.transactions = const [],
    this.error,
    this.currencyCode = 'GBP',
  });

  WalletState copyWith({
    bool? isLoading,
    double? balance,
    List<Map<String, dynamic>>? transactions,
    String? error,
    String? currencyCode,
  }) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      error: error ?? this.error,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final Dio _dio;

  WalletNotifier(this._dio) : super(WalletState());

  Future<void> fetchWalletData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Fetch Profile for Balance
      final profileResponse = await _dio.get('/me');
      // Assuming 'wallet' relationship or 'wallet_balance' on user. 
      // Based on User model, it has 'wallet' HasOne relationship.
      // We might need to ensure /me returns wallet or fetch separately.
      // Ideally backend /me should include wallet or we fetch /wallet/balance if exists.
      // Let's assume /me returns 'wallet': {'balance': ...} or similar.
      // If not, we might need a dedicated endpoint.
      // For now, let's try to fetch /profile which typically has this info or use /me.
      
      // Let's use a dedicated call if possible, or assume /me.
      // If /me doesn't have it, we might need to add it to backend UserResource.
      // Checking AuthController me() returns $request->user().
      // Laravel default serialization includes relations if loaded, or attributes.
      // User model has wallet() relation but it might not be loaded.
      
      // Better approach: Create a specific wallet logic here or rely on what we have.
      // Since we just added confirmPayment returning balance, we know structure there.
      
      // Let's fetch /profile (ProfileController@show) which usually loads more data.
      final response = await _dio.get('/profile');
      final data = response.data; // The /profile endpoint returns the user object directly
      
      // Parse balance
      final wallet = data['wallet'] ?? {};
      final balance = (wallet['balance'] ?? 0.0).toDouble();
      final currency = wallet['currency'] ?? 'GBP';

      // Fetch Transactions
      final txResponse = await _dio.get('/wallet/transactions');
      final List<Map<String, dynamic>> transactions = 
          List<Map<String, dynamic>>.from(txResponse.data['transactions']);
      
      state = state.copyWith(isLoading: false, balance: balance, transactions: transactions, currencyCode: currency);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateBalance(double newBalance) {
    state = state.copyWith(balance: newBalance);
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WalletNotifier(apiClient.dio);
});
