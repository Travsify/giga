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

  Future<void> fetchRates() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.get('/currency-rates');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        _rates = List<Map<String, dynamic>>.from(data);
        
        // Cache locally
        await _storage.write(key: 'currency_rates', value: jsonEncode(_rates));
        debugPrint('CurrencyService: Rates fetched and cached: ${_rates.length}');
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

  double getRate(String currencyCode) {
    if (_rates.isEmpty) return _fallbackRates[currencyCode] ?? 1.0;
    
    final rateObj = _rates.firstWhere(
      (r) => r['currency_code'] == currencyCode, 
      orElse: () => {'rate_to_gbp': _fallbackRates[currencyCode] ?? 1.0}
    );
    
    // Ensure we return double
    return double.tryParse(rateObj['rate_to_gbp'].toString()) ?? 1.0;
  }

  double convertFromGbp(double amountInGbp, String targetCurrency) {
    final rate = getRate(targetCurrency);
    return amountInGbp * rate;
  }
  
  double convertToGbp(double amountInLocal, String localCurrency) {
    final rate = getRate(localCurrency);
    if (rate == 0) return 0;
    return amountInLocal / rate;
  }
  
  String getSymbol(String currencyCode) {
    if (_rates.isEmpty) {
       if (currencyCode == 'NGN') return '₦';
       if (currencyCode == 'USD') return '\$';
       if (currencyCode == 'EUR') return '€';
       return '£';
    }
    
    final rateObj = _rates.firstWhere(
      (r) => r['currency_code'] == currencyCode, 
      orElse: () => {'symbol': '£'}
    );
    return rateObj['symbol'] ?? '£';
  }
}
