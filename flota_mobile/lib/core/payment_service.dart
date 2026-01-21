import 'package:flutter/material.dart';
// TODO: Replace with a maintained Paystack package or official SDK.
// flutter_paystack is incompatible with modern Android build tools (Gradle 8+ / Kotlin 1.9+).
/*
import 'package:flutter/material.dart';
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  static final PaystackPlugin _paystack = PaystackPlugin();
  static const String _publicKey = 'pk_test_YOUR_PAYSTACK_PUBLIC_KEY'; 

  static Future<void> initialize() async {
    await _paystack.initialize(publicKey: _publicKey);
  }

  // Fund wallet
  static Future<bool> fundWallet(BuildContext context, double amount, String email) async {
    try {
      Charge charge = Charge()
        ..amount = (amount * 100).toInt()
        ..email = email
        ..reference = 'FLT_${DateTime.now().millisecondsSinceEpoch}'
        ..currency = 'NGN';

      CheckoutResponse response = await _paystack.checkout(
        context,
        method: CheckoutMethod.card,
        charge: charge,
      );

      if (response.status && response.reference != null) {
        // Direct Firestore update (Demo only - use Cloud Functions in production)
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
          
          await FirebaseFirestore.instance.runTransaction((transaction) async {
             final snapshot = await transaction.get(userRef);
             final currentBalance = snapshot.data()?['wallet_balance'] ?? 0.0;
             transaction.update(userRef, {'wallet_balance': currentBalance + amount});
             
             // Add transaction record
             final txRef = userRef.collection('transactions').doc();
             transaction.set(txRef, {
               'amount': amount,
               'type': 'credit',
               'reference': response.reference,
               'created_at': FieldValue.serverTimestamp(),
               'description': 'Wallet funding'
             });
          });
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Payment error: $e');
      return false;
    }
  }

  // Pay for delivery
  static Future<bool> payForDelivery(
    BuildContext context,
    double amount,
    String email,
    String deliveryId,
  ) async {
    try {
      Charge charge = Charge()
        ..amount = (amount * 100).toInt()
        ..email = email
        ..reference = 'DEL_${deliveryId.substring(0, 5)}_${DateTime.now().millisecondsSinceEpoch}'
        ..currency = 'NGN';

      CheckoutResponse response = await _paystack.checkout(
        context,
        method: CheckoutMethod.card,
        charge: charge,
      );

      if (response.status && response.reference != null) {
         // Update delivery status
         await FirebaseFirestore.instance.collection('deliveries').doc(deliveryId).update({
           'status': 'paid',
           'payment_reference': response.reference,
           'updated_at': FieldValue.serverTimestamp(),
         });
         return true;
      }
      return false;
    } catch (e) {
      debugPrint('Payment error: $e');
      return false;
    }
  }
}
*/
class PaymentService {
  static Future<void> initialize() async {
    print('PaymentService disabled');
  }

  static Future<bool> fundWallet(BuildContext context, double amount, String email) async {
    print('PaymentService disabled');
    return false;
  }
    
  static Future<bool> payForDelivery(
    BuildContext context,
    double amount,
    String email,
    String deliveryId,
  ) async {
    print('PaymentService disabled');
     return false;
  }
}
