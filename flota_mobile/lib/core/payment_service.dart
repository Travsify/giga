import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flota_mobile/core/payment_config_service.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flota_mobile/core/currency_service.dart';
import 'dart:math';

// Render Production Backend
const String kApiBaseUrl = 'https://giga-ytn0.onrender.com/api'; 

class PaymentService {
  // static final _paystackPlugin = PaystackPlugin(); // Removed

  static Future<void> initialize() async {
    // 1. Fetch Remote Config
    await PaymentConfigService().fetchConfig();
    final config = PaymentConfigService();

    // 2. Initialize Stripe
    final stripeKey = config.stripePublicKey;
    if (stripeKey != null && stripeKey.isNotEmpty) {
      Stripe.publishableKey = stripeKey;
      debugPrint('PaymentService: Stripe Initialized with remote key');
    } else {
       // Fallback
       Stripe.publishableKey = 'pk_test_51R4NuyAEVFQTWQrKB3NZOOlWSqpFYyQZmMdEcFRVg6V0aHg07dr7UUfV1N2CabjUXoTbLLehUq7VpJQ6D2hJP8bM00HcerMi3h';
    }
  }

  // Unified Fund Wallet Method
  static Future<bool> fundWallet(BuildContext context, double amount, String email, String userId, {String currency = 'GBP'}) async {
    debugPrint('PaymentService: Starting fundWallet for $currency $amount');
    
    // 1. Determine Provider
    final africans = ['NGN', 'GHS', 'KES', 'ZAR', 'UGX', 'TZS', 'RWF'];
    if (africans.contains(currency)) {
      // Prefer Flutterwave if enabled and available, else Paystack for NGN/GHS, else Error
      final config = PaymentConfigService();
      
      if (config.flutterwaveEnabled && config.flutterwavePublicKey != null) {
         return await _fundWalletFlutterwave(context, amount, email, userId, currency);
      } else if (config.paystackEnabled && config.paystackPublicKey != null && (currency == 'NGN' || currency == 'GHS')) {
         return await _fundWalletPaystack(context, amount, email, currency);
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No payment provider available for this currency.')));
         return false;
      }
    } else {
      return await _fundWalletStripe(context, amount, email, userId, currency: currency);
    }
  }

  // FLUTTERWAVE FLOW
  static Future<bool> _fundWalletFlutterwave(BuildContext context, double amount, String email, String userId, String currency) async {
    final config = PaymentConfigService();
    // Use standard Flutterwave checkout
    final Customer customer = Customer(email: email, name: "Giga User", phoneNumber: "1234567890");
    final Flutterwave flutterwave = Flutterwave(
      publicKey: config.flutterwavePublicKey!, 
      currency: currency, 
      redirectUrl: "https://giga-ytn0.onrender.com", 
      txRef: "FLW_${DateTime.now().millisecondsSinceEpoch}", 
      amount: amount.toString(), 
      customer: customer, 
      paymentOptions: "card, mobilemoneyghana, ussd", 
      customization: Customization(title: "Giga Logistics Wallet Topup"), 
      isTestMode: true
    );
    
    try {
      final ChargeResponse response = await flutterwave.charge(context);
      if (response.success == true) { // Updated check based on typical response
         debugPrint('Flutterwave Success: ${response.transactionId}');
         return await _confirmPaymentWithBackend(response.transactionId ?? 'UNKNOWN_REF', 'flutterwave', amount, currency);
      } else {
         debugPrint('Flutterwave Failed');
         return false;
      }
    } catch (e) {
      debugPrint('Flutterwave Error: $e');
      return false;
    }
  }

  static Future<bool> _fundWalletPaystack(BuildContext context, double amount, String email, String currency) async {
       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Paystack is currently undergoing maintenance. Please use Flutterwave or Stripe.')),
         );
       }
       return false;
  }

  // STRIPE FLOW
  static Future<bool> _fundWalletStripe(BuildContext context, double amount, String email, String userId, {String currency = 'gbp'}) async {
    try {
      // 1. Create Payment Intent on Backend (Stripe always needs backend intent first)
      debugPrint('PaymentService: Creating Stripe payment intent...');
       final paymentIntent = await _createPaymentIntent(amount, currency);
       
       if (paymentIntent == null) {
         throw 'Failed to create payment intent.';
       }

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['clientSecret'],
          merchantDisplayName: 'Giga Logistics',
          style: ThemeMode.light,
        ),
      );

      // 3. Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();
      
      // 4. Confirm with Backend
      // Stripe uses the intent ID as reference
      final intentId = paymentIntent['id'] ?? (paymentIntent['clientSecret'] as String).split('_secret')[0];
      
      return await _confirmPaymentWithBackend(intentId, 'stripe', amount, currency);

    } on StripeException catch (e) {
      debugPrint('Stripe Error: ${e.error.localizedMessage}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Failed: ${e.error.localizedMessage}')));
      }
      return false;
    } catch (e) {
      debugPrint('Payment Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Error: $e')));
      }
      return false;
    }
  }

  // Backend Confirmation (Used by both)
  static Future<bool> _confirmPaymentWithBackend(String reference, String provider, double amount, String currency) async {
      final dio = await _getAuthenticatedDio();
      
      try {
        final confirmResponse = await dio.post('/payment/confirm', data: {
          'payment_intent_id': reference, // or reference key based on backend logic
          'provider': provider,
          'amount': amount,
          'currency': currency,
        });

        if (confirmResponse.statusCode == 200) {
          debugPrint('Payment confirmed by backend.');
          return true;
        } else {
          throw 'Backend confirmation failed: ${confirmResponse.data}';
        }
      } catch (e) {
        debugPrint('Backend Confirmation Error: $e');
        return false; // Payment succeeded at Gateway, but failed to record? 
        // In prod, use webhooks to handle this case!
      }
  }

  static Future<Dio> _getAuthenticatedDio() async {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw 'Authentication token not found';
      
      return Dio(BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
         }
      ));
  }

  // Create Payment Intent via Backend (For Stripe)
  static Future<Map<String, dynamic>?> _createPaymentIntent(double amount, String currency) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));

      final response = await dio.post(
        '$kApiBaseUrl/create-payment-intent-public',
        data: {
          'amount': amount,
          'currency': currency,
        },
        options: Options(contentType: Headers.jsonContentType),
      );

      return response.data;
    } catch (e) {
      debugPrint('Error creating payment intent: $e');
      throw 'Connection error: $e';
    }
  }
    


  static Future<Map<String, dynamic>> redeemGiftCard(String pin, String userId) async {
    final dio = await _getAuthenticatedDio();
    try {
      final response = await dio.post('/wallet/redeem', data: {
        'code': pin.trim().toUpperCase(),
      });
      return {
        'amount': response.data['amount'],
        'reference': 'GIGA-REDEEM',
      };
    } on DioException catch (e) {
        throw e.response?.data['error'] ?? 'Redemption failed';
    }
  }
}
