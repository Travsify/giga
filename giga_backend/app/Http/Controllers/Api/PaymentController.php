<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Stripe\Stripe;
use Stripe\PaymentIntent;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    public function diag()
    {
        return response()->json([
            'status' => 'ok',
            'time' => now()->toDateTimeString(),
            'env' => [
                'STRIPE_SECRET_SET' => !empty(env('STRIPE_SECRET')),
                'STRIPE_SECRET_PLACEHOLDER' => env('STRIPE_SECRET') === 'sk_test_your_stripe_secret_key_here',
                'APP_URL' => env('APP_URL'),
                'DB_CONNECTION' => env('DB_CONNECTION'),
            ]
        ]);
    }

    public function createPaymentIntent(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:1',
            'currency' => 'required|string|in:gbp,usd,eur',
        ]);

        try {
            // Set your secret key. Remember to switch to your live secret key in production.
            // See your keys here: https://dashboard.stripe.com/apikeys
            Stripe::setApiKey(env('STRIPE_SECRET'));

            // Amount in cents/pence
            $amount = $request->amount * 100; 

            $paymentIntent = PaymentIntent::create([
                'amount' => $amount,
                'currency' => $request->currency,
                'automatic_payment_methods' => [
                    'enabled' => true,
                ],
                'metadata' => [
                    'user_id' => $request->user()->id,
                    'email' => $request->user()->email,
                ],
            ]);

            return response()->json([
                'clientSecret' => $paymentIntent->client_secret,
            ]);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    // Public version for demo (no user metadata)
    public function createPaymentIntentPublic(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:1',
            'currency' => 'required|string|in:gbp,usd,eur',
        ]);

        try {
            \Log::info('Creating payment intent for amount: ' . $request->amount . ' ' . $request->currency);
            $secret = env('STRIPE_SECRET');
            if (empty($secret) || $secret === 'sk_test_your_stripe_secret_key_here') {
                return response()->json(['error' => 'STRIPE_SECRET is missing or using placeholder in Render env variables.'], 500);
            }
            Stripe::setApiKey($secret);
            $amount = $request->amount * 100; 

            $paymentIntent = PaymentIntent::create([
                'amount' => $amount,
                'currency' => $request->currency,
                'automatic_payment_methods' => [
                    'enabled' => true,
                ],
            ]);

            return response()->json([
                'clientSecret' => $paymentIntent->client_secret,
            ]);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }
    public function confirmPayment(Request $request)
    {
        $request->validate([
            'payment_intent_id' => 'required|string',
        ]);

        try {
            // Retrieve the PaymentIntent from Stripe
            Stripe::setApiKey(env('STRIPE_SECRET'));
            $paymentIntent = \Stripe\PaymentIntent::retrieve($request->payment_intent_id);

            if ($paymentIntent->status !== 'succeeded') {
                return response()->json(['message' => 'Payment not successful. Status: ' . $paymentIntent->status], 400);
            }

            $user = $request->user();
            $amount = $paymentIntent->amount / 100; // Convert cents to main currency unit
            
            // Check if transaction already recorded to prevent duplicates (idempotency)
            $existingTx = $user->wallet 
                ? $user->wallet->transactions()->where('reference', $request->payment_intent_id)->first()
                : null;
                
            if ($existingTx) {
                return response()->json(['message' => 'Transaction already processed', 'balance' => $user->wallet->balance, 'success' => true]);
            }

            // Update Wallet
            $wallet = $user->wallet()->firstOrCreate([], ['balance' => 0.00, 'currency' => 'GBP']);
            $wallet->balance += $amount;
            $wallet->save();

            // Record Transaction
            $wallet->transactions()->create([
                'amount' => $amount,
                'type' => 'credit',
                'description' => 'Wallet Top-up (Stripe)',
                'reference' => $request->payment_intent_id,
                'status' => 'completed',
                'currency' => strtoupper($paymentIntent->currency),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Payment confirmed and wallet credited.',
                'balance' => $wallet->balance,
            ]);

        } catch (\Exception $e) {
            Log::error('Payment Confirmation Error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to confirm payment: ' . $e->getMessage()], 500);
        }
    }
    public function redeem(Request $request) {
        $request->validate(['code' => 'required|string']);

        try {
            return \Illuminate\Support\Facades\DB::transaction(function () use ($request) {
                // 1. Find the card
                $card = \App\Models\GiftCard::where('code', $request->code)
                    ->where('is_active', true)
                    ->lockForUpdate() // Prevent race conditions
                    ->first();

                if (!$card) {
                    return response()->json(['error' => 'Invalid or inactive gift card'], 404);
                }

                // 2. Validate Expiry
                if ($card->expires_at && $card->expires_at->isPast()) {
                    return response()->json(['error' => 'This gift card has expired'], 400);
                }

                // 3. Validate Usage Limit
                if ($card->current_uses >= $card->max_uses) {
                    return response()->json(['error' => 'This gift card has technically been fully redeemed.'], 400);
                }

                $user = $request->user();

                // 4. Validate Currency Mismatch (CRITICAL)
                // If user has no wallet yet, we allow creating one with the card's currency
                // But if they have a wallet, it MUST match.
                $wallet = $user->wallet()->firstOrCreate(
                    [], 
                    ['balance' => 0.00, 'currency' => $card->currency_code]
                );

                if (strtoupper($wallet->currency) !== strtoupper($card->currency_code)) {
                    return response()->json([
                        'error' => "Currency Mismatch. This card is in {$card->currency_code} but your wallet is in {$wallet->currency}."
                    ], 400);
                }

                // 5. Credit Wallet
                $wallet->balance += $card->amount;
                $wallet->save();

                // 6. Record Transaction
                $wallet->transactions()->create([
                    'amount' => $card->amount,
                    'type' => 'credit',
                    'description' => 'Gift Card Redeemed: ' . $card->code, // Masked in prod usually
                    'reference' => 'GIFT_' . $card->id . '_' . time(),
                    'status' => 'completed',
                    'currency' => $card->currency_code,
                    'category' => 'gift_card'
                ]);

                // 7. Increment Usage
                $card->increment('current_uses');

                return response()->json([
                    'success' => true,
                    'message' => 'Gift card redeemed successfully!',
                    'amount' => $card->amount,
                    'new_balance' => $wallet->balance,
                ]);
            });

        } catch (\Exception $e) {
             Log::error('Gift Card Redemption Error: ' . $e->getMessage());
             return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    public function getTransactions(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user->wallet) {
                return response()->json(['transactions' => []]);
            }

            $transactions = $user->wallet->transactions()
                ->orderBy('created_at', 'desc')
                ->limit(20)
                ->get()
                ->map(function ($tx) {
                    return [
                        'id' => $tx->id,
                        'amount' => $tx->amount,
                        'type' => $tx->type,
                        'description' => $tx->description,
                        'created_at' => $tx->created_at,
                        'reference' => $tx->reference,
                        'currency' => $tx->currency,
                    ];
                });

            return response()->json(['transactions' => $transactions]);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }
}
