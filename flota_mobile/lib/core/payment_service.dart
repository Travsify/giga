import 'package:flutter/material.dart';
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
  static final _paystackPlugin = PaystackPlugin();

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
    
    // 3. Initialize Paystack
    final paystackKey = config.paystackPublicKey;
    if (paystackKey != null && paystackKey.isNotEmpty) {
      try {
        await _paystackPlugin.initialize(publicKey: paystackKey);
        debugPrint('PaymentService: Paystack Initialized with remote key');
      } catch (e) {
        debugPrint('PaymentService: Paystack Init Failed: $e');
      }
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
    if (config.flutterwavePublicKey == null) return false;

    // Use a unique ref
    final txRef = 'FLW_${DateTime.now().millisecondsSinceEpoch}';

    final Customer customer = Customer(
      name: email.split('@')[0],
      phoneNumber: "1234567890", // Optional/User provided
      email: email,
    );

    final Flutterwave flutterwave = Flutterwave(
      context: context,
      publicKey: config.flutterwavePublicKey!,
      currency: currency,
      redirectUrl: "https://google.com",
      txRef: txRef,
      amount: amount.toString(),
      customer: customer,
      paymentOptions: "card, payattitude, barter, bank transfer, ussd",
      customization: Customization(title: "Wallet Topup"),
      isTestMode: true, // TODO: Toggle based on env
    );

    try {
      final ChargeResponse response = await flutterwave.charge();
      
      if (response.success == true && response.txRef == txRef) {
          debugPrint('Flutterwave Success: ${response.transactionId}');
          return await _confirmPaymentWithBackend(response.transactionId!, 'flutterwave', amount, currency);
      } else {
         debugPrint('Flutterwave Failed/Cancelled');
         return false;
      }
    } catch (e) {
      debugPrint('Flutterwave Error: $e');
      return false;
    }
  }

  // PAYSTACK FLOW (REAL)
  static Future<bool> _fundWalletPaystack(BuildContext context, double amount, String email, String currency) async {
      final config = PaymentConfigService();
      if (config.paystackPublicKey == null) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paystack is not configured (Missing public key)')));
          return false;
      }

      if (!_paystackPlugin.sdkInitialized) {
         await _paystackPlugin.initialize(publicKey: config.paystackPublicKey!);
      }

      try {
        final int amountInSubunits = (amount * 100).ceil();
        
        PaystackCharge charge = PaystackCharge()
          ..amount = amountInSubunits
          ..email = email
          ..currency = currency
          ..reference = 'PAY_${DateTime.now().millisecondsSinceEpoch}';

        var response = await _paystackPlugin.checkout(
          context,
 
          charge: charge,
          logo: const Icon(Icons.wallet, size: 24),
        );

        if (response.status == true) {
           debugPrint('Paystack Success: ${response.reference}');
           return await _confirmPaymentWithBackend(response.reference!, 'paystack', amount, currency);
        } else {
           if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Failed: ${response.message}')));
           return false;
        }

      } catch (e) {
         debugPrint('Paystack Error: $e');
         if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Paystack Error: $e')));
         return false;
      }
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
    
  static Future<bool> payForDelivery(BuildContext context, double amount, String email, String deliveryId) async {
    // Legacy mock function - update if needed or deprecated
    debugPrint('MockPaymentService: Paying for delivery $deliveryId - $amount');
    await Future.delayed(const Duration(seconds: 2));
    // ... Mock logic ...
    return true;
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
