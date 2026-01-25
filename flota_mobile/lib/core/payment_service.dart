import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';

// Render Production Backend
const String kApiBaseUrl = 'https://giga-ytn0.onrender.com/api'; 

// NOTE: flutter_paystack is currently incompatible with the project's build configuration.
// We are using a MockPaymentService to allow the app to be built and functionality tested.
// TODO: Integrate a new payment gateway (e.g., Stripe) suitable for the UK market.

class PaymentService {
  static Future<void> initialize() async {
    // Initialize Stripe
    Stripe.publishableKey = 'pk_test_51R4NuyAEVFQTWQrKB3NZOOlWSqpFYyQZmMdEcFRVg6V0aHg07dr7UUfV1N2CabjUXoTbLLehUq7VpJQ6D2hJP8bM00HcerMi3h';
    debugPrint('PaymentService: Stripe Initialized');
  }

  static Future<bool> fundWallet(BuildContext context, double amount, String email, String userId, {String currency = 'gbp'}) async {
    debugPrint('PaymentService: Starting fundWallet for $currency $amount');
    try {
      // 1. Create Payment Intent on Backend
      debugPrint('PaymentService: Creating payment intent...');
       final paymentIntent = await _createPaymentIntent(amount, currency);
       
       if (paymentIntent == null) {
         debugPrint('PaymentService: Payment intent creation failed');
         throw 'Failed to create payment intent. Please check your internet connection or server status.';
       }
       debugPrint('PaymentService: Payment intent created successfully');

      // 2. Initialize Payment Sheet
      debugPrint('PaymentService: Initializing payment sheet...');
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['clientSecret'],
          merchantDisplayName: 'Giga Logistics',
          style: ThemeMode.light,
        ),
      );
      debugPrint('PaymentService: Payment sheet initialized');

      // 3. Present Payment Sheet
      debugPrint('PaymentService: Presenting payment sheet...');
      await Stripe.instance.presentPaymentSheet();
      debugPrint('PaymentService: Payment sheet dismissed (Success)');

      // 4. Confirm with Backend
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      
      if (token == null) {
        throw 'Authentication token not found. Please log in again.';
      }

      final dio = Dio(BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
         }
      ));

      final confirmResponse = await dio.post('/payment/confirm', data: {
        'payment_intent_id': paymentIntent['id'], // Assuming paymentIntent contains the ID
      });

      if (confirmResponse.statusCode == 200) {
        debugPrint('Payment confirmed by backend: ${confirmResponse.data}');
      } else {
        throw 'Backend confirmation failed: ${confirmResponse.data}';
      }

      return true;
    } on StripeException catch (e) {
      debugPrint('Stripe Error: ${e.error.localizedMessage}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment Failed: ${e.error.localizedMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } catch (e) {
      debugPrint('Payment Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return false;
    }
  }

  // Create Payment Intent via Backend
  static Future<Map<String, dynamic>?> _createPaymentIntent(double amount, String currency) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
      // Get current user token if needed for auth
      // final user = FirebaseAuth.instance.currentUser;
      // final token = await user?.getIdToken(); 
      // dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await dio.post(
        '$kApiBaseUrl/create-payment-intent-public',
        data: {
          'amount': amount,
          'currency': currency,
        },
        options: Options(
            contentType: Headers.jsonContentType,
            headers: {
              'Accept': 'application/json',
            },
            validateStatus: (status) => status! < 500, // Handle 400s manually
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        debugPrint('Backend Error: ${response.data}');
        final errorMsg = response.data?['error'] ?? response.data?['message'] ?? 'Unknown error';
        throw 'Backend Error (${response.statusCode}): $errorMsg';
      }
    } on DioException catch (e) {
      debugPrint('Network Error creating payment intent: $e');
      String msg = 'Network Error';
      if (e.response != null) {
        msg += ' (${e.response?.statusCode}): ${e.response?.data}';
      } else {
        msg += ': ${e.message}';
      }
      throw msg;
    } catch (e) {
      debugPrint('Error creating payment intent: $e');
      throw 'Connection error: $e';
    }
  }
    
  static Future<bool> payForDelivery(
    BuildContext context,
    double amount,
    String email,
    String deliveryId,
  ) async {
    debugPrint('MockPaymentService: Paying for delivery $deliveryId - £$amount');
    
    await Future.delayed(const Duration(seconds: 2));
    
    final mockRef = 'MOCK_DEL_${Random().nextInt(99999)}';

    try {
       await FirebaseFirestore.instance.collection('deliveries').doc(deliveryId).update({
         'status': 'paid',
         'payment_reference': mockRef,
         'updated_at': FieldValue.serverTimestamp(),
       });
       return true;
    } catch (e) {
      debugPrint('MockPaymentService Error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> redeemGiftCard(String pin, String userId) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw 'Authentication token not found';

    final dio = Dio(BaseOptions(
      baseUrl: kApiBaseUrl,
      headers: {
        'Authorization': 'Bearer $token', 
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }
    ));

    try {
      final response = await dio.post('/wallet/redeem', data: {
        'code': pin.trim().toUpperCase(),
      });

      return {
        'amount': response.data['amount'],
        'reference': 'GIGA-REDEEM',
      };
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
         throw e.response!.data['error'] ?? 'Redemption failed';
      }
      throw 'Network error: ${e.message}';
    }
  }
}
