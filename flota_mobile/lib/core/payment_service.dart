import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'dart:math';

// Base URL for Android Emulator (10.0.2.2 points to localhost)
// For physical device, use your machine's IP address
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

  static Future<bool> fundWallet(BuildContext context, double amount, String email) async {
    try {
      // 1. Create Payment Intent on Backend
      // TODO: Replace with actual backend call (Dio)
       final paymentIntent = await _createPaymentIntent(amount, 'gbp');
       
       if (paymentIntent == null) throw 'Failed to create payment intent';

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

      // 4. If successful, confirm with backend and update wallet
      // In a real flow, the webhook handles this safely. 
      // For now, we manually assume success and update Firestore.
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
          final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
          final mockRef = 'STRIPE_${DateTime.now().millisecondsSinceEpoch}';

          await FirebaseFirestore.instance.runTransaction((transaction) async {
             final snapshot = await transaction.get(userRef);
             final currentBalance = snapshot.data()?['wallet_balance'] ?? 0.0;
             transaction.update(userRef, {'wallet_balance': currentBalance + amount});
             
             // Add transaction record
             final txRef = userRef.collection('transactions').doc();
             transaction.set(txRef, {
               'amount': amount,
               'type': 'credit',
               'reference': mockRef,
               'created_at': FieldValue.serverTimestamp(),
               'description': 'Wallet Funding (Stripe)',
               'currency': 'GBP',
             });
          });
          return true;
      }
      return false;
      
    } on StripeException catch (e) {
      debugPrint('Stripe Error: ${e.error.localizedMessage}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed: ${e.error.localizedMessage}')),
      );
      return false;
    } catch (e) {
      debugPrint('Payment Error: $e');
      return false;
    }
  }

  // Create Payment Intent via Backend
  static Future<Map<String, dynamic>?> _createPaymentIntent(double amount, String currency) async {
    try {
      final dio = Dio();
      // Get current user token if needed for auth
      // final user = FirebaseAuth.instance.currentUser;
      // final token = await user?.getIdToken(); 
      // dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await dio.post(
        '$kApiBaseUrl/create-payment-intent',
        data: {
          'amount': amount,
          'currency': currency,
        },
        options: Options(
            contentType: Headers.jsonContentType,
            validateStatus: (status) => status! < 500, // Handle 400s manually
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        debugPrint('Backend Error: ${response.data}');
        return null;
      }
    } catch (e) {
      debugPrint('Network Error creating payment intent: $e');
      return null;
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
}
