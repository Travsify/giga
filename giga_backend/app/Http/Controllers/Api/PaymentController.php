<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Stripe\Stripe;
use Stripe\PaymentIntent;
use Illuminate\Support\Facades\Log;
use App\Models\AppSetting;

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
            $secret = \App\Models\AppSetting::get('stripe_secret_key') ?? env('STRIPE_SECRET');
            if (!$secret) throw new \Exception('Stripe not configured');
            
            Stripe::setApiKey($secret);

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
            
            $secret = \App\Models\AppSetting::get('stripe_secret_key') ?? env('STRIPE_SECRET');
            
            if (empty($secret) || $secret === 'sk_test_your_stripe_secret_key_here') {
                return response()->json(['error' => 'STRIPE_SECRET is missing or using placeholder.'], 500);
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
            'provider' => 'nullable|string|in:stripe,paystack,flutterwave',
            'amount' => 'nullable|numeric',
            'currency' => 'nullable|string',
        ]);

        try {
            $user = $request->user();
            $provider = $request->provider ?? 'stripe';
            $reference = $request->payment_intent_id;
            
            $amount = 0.0;
            $currency = 'GBP';

            if ($provider === 'stripe') {
                $stripeSecret = AppSetting::get('stripe_secret_key');
                if (!$stripeSecret) {
                    return response()->json(['error' => 'Stripe is not configured.'], 500);
                }
                Stripe::setApiKey($stripeSecret);
                
                $paymentIntent = \Stripe\PaymentIntent::retrieve($reference);

                if ($paymentIntent->status !== 'succeeded') {
                    return response()->json(['message' => 'Payment not successful. Status: ' . $paymentIntent->status], 400);
                }
                $amount = $paymentIntent->amount / 100;
                $currency = strtoupper($paymentIntent->currency);
            } 
            elseif ($provider === 'paystack') {
                $paystackSecret = AppSetting::get('paystack_secret_key');
                if (!$paystackSecret) {
                     // Fallback for development if not set in DB yet
                     $paystackSecret = env('PAYSTACK_SECRET_KEY'); 
                }
                
                if (!$paystackSecret) {
                     return response()->json(['error' => 'Paystack is not configured.'], 500);
                }

                // Verify with Paystack API
                $response = \Illuminate\Support\Facades\Http::withHeaders([
                    'Authorization' => 'Bearer ' . $paystackSecret,
                    'Content-Type' => 'application/json',
                ])->get('https://api.paystack.co/transaction/verify/' . $reference);
                
                if (!$response->successful() || !$response->json()['status']) {
                    return response()->json(['message' => 'Paystack verification failed: ' . ($response->json()['message'] ?? 'Unknown error')], 400);
                }
                
                $data = $response->json()['data'];
                if ($data['status'] !== 'success') {
                     return response()->json(['message' => 'Payment failed or incomplete'], 400);
                }
                
                // Paystack returns amount in kobo
                $amount = $data['amount'] / 100; 
                $currency = strtoupper($data['currency']);
            }
            elseif ($provider === 'flutterwave') {
                $flwSecret = AppSetting::get('flutterwave_secret_key');
                 if (!$flwSecret) {
                     $flwSecret = env('FLUTTERWAVE_SECRET_KEY') ?? env('FLW_SECRET_KEY');
                 }
                 
                 if (!$flwSecret) {
                     return response()->json(['error' => 'Flutterwave is not configured.'], 500);
                }

                // Verify with Flutterwave API (v3)
                $response = \Illuminate\Support\Facades\Http::withHeaders([
                    'Authorization' => 'Bearer ' . $flwSecret,
                    'Content-Type' => 'application/json',
                ])->get('https://api.flutterwave.com/v3/transactions/' . $reference . '/verify');
                
                if (!$response->successful() || $response->json()['status'] !== 'success') {
                     return response()->json(['message' => 'Flutterwave verification failed: ' . ($response->json()['message'] ?? 'Unknown error')], 400);
                }

                $data = $response->json()['data'];
                if ($data['status'] !== 'successful') {
                     return response()->json(['message' => 'Payment failed or incomplete'], 400);
                }
                
                $amount = $data['amount'];
                $currency = strtoupper($data['currency']);
            }

            return \Illuminate\Support\Facades\DB::transaction(function () use ($user, $provider, $reference, $amount, $currency) {
                // Check duplicate within transaction
                $existingTx = $user->wallet 
                    ? $user->wallet->transactions()->where('reference', $reference)->first()
                    : null;
                    
                if ($existingTx) {
                    return response()->json(['message' => 'Transaction already processed', 'balance' => $user->wallet->balance, 'success' => true]);
                }

                // Update Wallet
                $wallet = $user->wallet()->firstOrCreate([], ['balance' => 0.00, 'currency' => strtoupper($currency)]);
                
                $walletCurrency = strtoupper($wallet->currency);
                $txCurrency = strtoupper($currency);
                $creditAmount = $amount;
                
                if ($walletCurrency !== $txCurrency) {
                     $rate = \App\Models\CurrencyRate::where('currency_code', $txCurrency)->first();
                     if ($rate && $rate->rate_to_gbp > 0) {
                         $creditAmount = $amount / $rate->rate_to_gbp;
                     } else {
                         // Basic fallback for common pairs if rates missing
                         if ($txCurrency == 'NGN' && $walletCurrency == 'GBP') $creditAmount = $amount / 2000;
                         if ($txCurrency == 'GBP' && $walletCurrency == 'NGN') $creditAmount = $amount * 2000;
                     }
                }

                $wallet->increment('balance', $creditAmount);

                // Record Transaction
                $wallet->transactions()->create([
                    'amount' => $creditAmount,
                    'type' => 'credit',
                    'description' => "Wallet Top-up via " . ucfirst($provider),
                    'reference' => $reference,
                    'status' => 'completed',
                    'currency' => $txCurrency, 
                    'metadata' => json_encode(['original_amount' => $amount, 'original_currency' => $txCurrency]),
                ]);

                // Trigger Notification
                try {
                    $user->notify(new \App\Notifications\WalletTopupNotification($creditAmount, $wallet->balance, $walletCurrency, $provider));
                } catch (\Exception $e) {
                    Log::error('Failed to send top-up notification: ' . $e->getMessage());
                }

                Log::info("Payment confirmed: $provider | Ref: $reference | Amount: $creditAmount $walletCurrency");

                return response()->json([
                    'success' => true,
                    'message' => 'Payment confirmed and wallet credited.',
                    'balance' => $wallet->balance,
                    'currency' => $walletCurrency
                ]);
            });

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
