import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flota_mobile/core/payment_service.dart'; // for kApiBaseUrl

class PaymentConfigService {
  static final PaymentConfigService _instance = PaymentConfigService._internal();
  factory PaymentConfigService() => _instance;
  PaymentConfigService._internal();

  String? stripePublicKey;
  String? paystackPublicKey;
  String? flutterwavePublicKey;
  String? flutterwaveEncryptionKey;
  bool paystackEnabled = false;
  bool flutterwaveEnabled = false;

  final _storage = const FlutterSecureStorage();

  Future<void> fetchConfig() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.get('/settings/payment');
      
      if (response.statusCode == 200) {
        final data = response.data;
        stripePublicKey = data['stripe_public_key'];
        paystackPublicKey = data['paystack_public_key'];
        flutterwavePublicKey = data['flutterwave_public_key'];
        flutterwaveEncryptionKey = data['flutterwave_encryption_key']; // Optional if needed by SDK
        
        paystackEnabled = data['paystack_enabled'] ?? false;
        flutterwaveEnabled = data['flutterwave_enabled'] ?? false;
        
        await _storage.write(key: 'stripe_key', value: stripePublicKey);
        await _storage.write(key: 'paystack_key', value: paystackPublicKey);
        await _storage.write(key: 'flutterwave_key', value: flutterwavePublicKey);
        
        debugPrint('Payment Config Loaded: Stripe=${stripePublicKey != null}, Paystack=${paystackPublicKey != null}, Flutterwave=${flutterwavePublicKey != null}');
      }
    } catch (e) {
      debugPrint('Error fetching payment config: $e');
      // Fallback to cache
      stripePublicKey = await _storage.read(key: 'stripe_key');
      paystackPublicKey = await _storage.read(key: 'paystack_key');
      flutterwavePublicKey = await _storage.read(key: 'flutterwave_key');
    }
  }
}
