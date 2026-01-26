import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'payment_service.dart'; // For API URL

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  List<Map<String, dynamic>> _rates = [];
  final _storage = const FlutterSecureStorage();
  
  // Default fallback rates
  final Map<String, double> _fallbackRates = {
    'GBP': 1.0,
    'USD': 1.27,
    'EUR': 1.17,
    'NGN': 2000.0,
  };

  // Fetch active currencies from backend
  Future<void> fetchRates() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.get('/currencies');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _rates = List<Map<String, dynamic>>.from(data);
        
        // Cache locally
        await _storage.write(key: 'currency_rates', value: jsonEncode(_rates));
        debugPrint('CurrencyService: Currencies fetched: ${_rates.length}');
      }
    } catch (e) {
      debugPrint('CurrencyService: Failed to fetch rates: $e');
      // Try load from cache
      final cached = await _storage.read(key: 'currency_rates');
      if (cached != null) {
        _rates = List<Map<String, dynamic>>.from(jsonDecode(cached));
      }
    }
  }

  // Returns how many Naira make 1 unit of this currency
  double getRateToNaira(String currencyCode) {
    if (currencyCode == 'NGN') return 1.0;
    if (_rates.isEmpty) return _fallbackRates[currencyCode] ?? 1.0;

    final rateObj = _rates.firstWhere(
      (r) => r['code'] == currencyCode, 
      orElse: () => {'rate_to_naira': _fallbackRates[currencyCode] ?? 1.0}
    );
    
    return double.tryParse(rateObj['rate_to_naira'].toString()) ?? 1.0;
  }

  // Convert NGN amount to Target Currency
  double convertFromNaira(double amountInNaira, String targetCurrency) {
    if (targetCurrency == 'NGN') return amountInNaira;
    final rate = getRateToNaira(targetCurrency); 
    if (rate == 0) return 0;
    // Example: 1500 NGN / 1500 (Rate) = 1 USD
    return amountInNaira / rate; 
  }
  
  // Convert Target Currency to NGN
  double convertToNaira(double amountInLocal, String localCurrency) {
    if (localCurrency == 'NGN') return amountInLocal;
    final rate = getRateToNaira(localCurrency);
    return amountInLocal * rate;
  }
  
  String getSymbol(String currencyCode) {
    if (currencyCode == 'NGN') return '₦';
    
    final rateObj = _rates.firstWhere(
      (r) => r['code'] == currencyCode, 
      orElse: () => {'symbol': getFallbackSymbol(currencyCode)}
    );
    return rateObj['symbol'] ?? getFallbackSymbol(currencyCode);
  }

  String getFallbackSymbol(String code) {
     if (code == 'USD') return '\$';
     if (code == 'GBP') return '£';
     if (code == 'EUR') return '€';
     return code;
  }
}
