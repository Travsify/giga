<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Stripe\Stripe;
use Stripe\PaymentIntent;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

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
            Log::info('Creating payment intent for amount: ' . $request->amount . ' ' . $request->currency);
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
                        'status' => $tx->status ?? 'completed',
                    ];
                });

            return response()->json(['transactions' => $transactions]);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Handle fund withdrawal requests.
     */
    /**
     * Handle fund withdrawal requests.
     */
    public function withdraw(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:1',
            'bank_account_id' => 'required|exists:bank_accounts,id',
        ]);

        try {
            $user = $request->user();
            $rider = $user->rider;
            $wallet = $user->wallet;
            $bankAccount = \App\Models\BankAccount::findOrFail($request->bank_account_id);

            // Security check
            if ($bankAccount->rider_id !== $rider->id) {
                return response()->json(['error' => 'Unauthorized bank account'], 403);
            }

            if (!$wallet || $wallet->balance < $request->amount) {
                return response()->json(['error' => 'Insufficient funds'], 400);
            }

            // Reference for the transaction
            $reference = 'WITHDRAW_' . time() . '_' . $user->id;

            // Payout Logic based on gateway
            if ($bankAccount->gateway_type === 'flutterwave') {
                $flw = new \App\Services\FlutterwaveTransferService();
                $result = $flw->initiateTransfer([
                    'bank_code' => $bankAccount->bank_code,
                    'account_number' => $bankAccount->account_number,
                    'amount' => $request->amount,
                    'currency' => $wallet->currency,
                    'reference' => $reference,
                ]);

                if (!$result['success']) {
                    return response()->json(['error' => $result['message']], 400);
                }
            } else {
                $stripe = new \App\Services\StripePayoutService();
                $result = $stripe->initiatePayout($request->amount, strtolower($wallet->currency));

                if (!$result['success']) {
                    return response()->json(['error' => $result['message']], 400);
                }
            }

            // Deduct from wallet
            $wallet->balance -= $request->amount;
            $wallet->save();

            // Record Transaction
            $transaction = $wallet->transactions()->create([
                'amount' => -$request->amount,
                'type' => 'debit',
                'description' => 'Withdrawal to ' . $bankAccount->bank_name . ' (' . $bankAccount->account_number . ')',
                'reference' => $reference,
                'status' => 'completed', // In real prod, this might stay 'pending' until webhook
                'currency' => $wallet->currency,
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Withdrawal processed successfully.',
                'balance' => $wallet->balance,
                'data' => $transaction
            ]);

        } catch (\Exception $e) {
            Log::error('Withdrawal Error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to process withdrawal: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Handle user-to-user fund transfers.
     */
    public function transfer(Request $request)
    {
        $request->validate([
            'recipient_email' => 'required|email|exists:users,email',
            'amount' => 'required|numeric|min:1',
        ]);

        try {
            return DB::transaction(function () use ($request) {
                $sender = $request->user();
                $recipient = \App\Models\User::where('email', $request->recipient_email)->first();

                if ($sender->id === $recipient->id) {
                    return response()->json(['error' => 'Cannot transfer to yourself'], 400);
                }

                $senderWallet = $sender->wallet;
                if (!$senderWallet || $senderWallet->balance < $request->amount) {
                    return response()->json(['error' => 'Insufficient funds'], 400);
                }

                // Currency check (Simplified: they must match for now)
                $recipientWallet = $recipient->wallet()->firstOrCreate(
                    [], 
                    ['balance' => 0, 'currency' => $senderWallet->currency]
                );

                if (strtoupper($senderWallet->currency) !== strtoupper($recipientWallet->currency)) {
                    return response()->json(['error' => 'Currency mismatch between accounts'], 400);
                }

                $reference = 'XFER_' . time() . '_' . $sender->id;

                // Deduct from sender
                $senderWallet->balance -= $request->amount;
                $senderWallet->save();

                $senderWallet->transactions()->create([
                    'amount' => -$request->amount,
                    'type' => 'debit',
                    'description' => 'Transfer to ' . $recipient->email,
                    'reference' => $reference,
                    'status' => 'completed',
                    'currency' => $senderWallet->currency,
                ]);

                // Credit recipient
                $recipientWallet->balance += $request->amount;
                $recipientWallet->save();

                $recipientWallet->transactions()->create([
                    'amount' => $request->amount,
                    'type' => 'credit',
                    'description' => 'Transfer from ' . $sender->email,
                    'reference' => $reference,
                    'status' => 'completed',
                    'currency' => $recipientWallet->currency,
                ]);

                return response()->json([
                    'status' => 'success',
                    'message' => 'Transfer completed successfully',
                    'balance' => $senderWallet->balance
                ]);
            });
        } catch (\Exception $e) {
            Log::error('Transfer Error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to process transfer'], 500);
        }
    }

    /**
     * Create a Flutterwave payment link/session.
     */
    public function createFlutterwavePayment(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:10',
            'currency' => 'required|string|in:NGN,GHS,KES,USD,GBP',
        ]);

        try {
            $user = $request->user();
            $reference = 'FLW_TOPUP_' . time() . '_' . $user->id;

            // Priority: Database Setting -> ENV variable
            $secretKey = \App\Models\AppSetting::get('flutterwave_secret_key', env('FLW_SECRET_KEY'));

            if (!$secretKey) {
                return response()->json(['error' => 'Flutterwave configuration missing'], 500);
            }

            Log::info('Initiating Flutterwave payment link request', [
                'user' => $user->id,
                'amount' => $request->amount,
                'currency' => $request->currency,
                'tx_ref' => $reference
            ]);

            $response = Http::withToken($secretKey)
                ->post('https://api.flutterwave.com/v3/payments', [
                    'tx_ref' => $reference,
                    'amount' => $request->amount,
                    'currency' => $request->currency,
                    'redirect_url' => request()->root() . '/api/wallet/flutterwave/callback',
                    'customer' => [
                        'email' => $user->email,
                        'name' => $user->name,
                    ],
                    'customizations' => [
                        'title' => 'Giga Wallet Top-up',
                        'description' => 'Funding Giga logistics wallet',
                    ],
                ]);

            if ($response->successful()) {
                Log::info('Flutterwave payment link created successfully', ['link' => $response->json('data.link')]);
                return response()->json([
                    'status' => 'success',
                    'checkout_url' => $response->json('data.link'),
                    'reference' => $reference
                ]);
            }

            Log::error('Flutterwave Payment Link API Error', [
                'status' => $response->status(),
                'body' => $response->json()
            ]);

            throw new \Exception('Flutterwave API error: ' . ($response->json('message') ?? $response->body()));
        } catch (\Exception $e) {
            Log::error('FLW Create Payment Error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to initialize payment: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Verify a Flutterwave payment.
     */
    public function verifyFlutterwavePayment(Request $request)
    {
        $request->validate([
            'transaction_id' => 'required|string',
        ]);

        try {
            $secretKey = env('FLW_SECRET_KEY');
            $response = Http::withToken($secretKey)
                ->get("https://api.flutterwave.com/v3/transactions/{$request->transaction_id}/verify");

            if ($response->successful() && $response->json('data.status') === 'successful') {
                $data = $response->json('data');
                $amount = $data['amount'];
                $currency = $data['currency'];
                $reference = $data['tx_ref'];

                $user = $request->user();
                
                // Idempotency check
                $existingTx = \App\Models\Transaction::where('reference', $reference)->first();
                if ($existingTx) {
                    return response()->json(['status' => 'success', 'message' => 'Already processed']);
                }

                $wallet = $user->wallet()->firstOrCreate([], ['balance' => 0, 'currency' => $currency]);
                $wallet->balance += $amount;
                $wallet->save();

                $wallet->transactions()->create([
                    'amount' => $amount,
                    'type' => 'credit',
                    'description' => 'Wallet Top-up (Flutterwave)',
                    'reference' => $reference,
                    'status' => 'completed',
                    'currency' => $currency,
                ]);

                return response()->json([
                    'status' => 'success',
                    'balance' => $wallet->balance
                ]);
            }

            return response()->json(['error' => 'Verification failed or payment not successful'], 400);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Handle Flutterwave payment redirect callback.
     * This is called by Flutterwave after payment completion via browser redirect.
     */
    public function flutterwaveCallback(Request $request)
    {
        Log::info('Flutterwave callback received', $request->all());

        $status = $request->query('status');
        $txRef = $request->query('tx_ref');
        $transactionId = $request->query('transaction_id');

        if ($status === 'successful' && $transactionId) {
            // Verify the payment
            $secretKey = \App\Models\AppSetting::get('flutterwave_secret_key', env('FLW_SECRET_KEY'));
            
            try {
                $response = Http::withToken($secretKey)
                    ->get("https://api.flutterwave.com/v3/transactions/{$transactionId}/verify");

                if ($response->successful() && $response->json('data.status') === 'successful') {
                    $amount = $response->json('data.amount');
                    $currency = $response->json('data.currency');
                    
                    // Extract user ID from tx_ref (format: FLW_TOPUP_timestamp_userid)
                    $parts = explode('_', $txRef);
                    $userId = end($parts);
                    
                    if ($userId) {
                        $user = \App\Models\User::find($userId);
                        if ($user && $user->wallet) {
                            $user->wallet->increment('balance', $amount);
                            $user->wallet->transactions()->create([
                                'type' => 'credit',
                                'amount' => $amount,
                                'description' => "Wallet funding via Flutterwave",
                                'reference' => $txRef,
                            ]);
                            Log::info('Wallet funded via callback', ['user' => $userId, 'amount' => $amount]);
                        }
                    }

                    // Return a success HTML page
                    return response()->make("
                        <html>
                        <head><title>Payment Successful</title>
                        <meta name='viewport' content='width=device-width, initial-scale=1'>
                        <style>
                            body { font-family: system-ui; text-align: center; padding: 40px; background: #0a1929; color: white; }
                            .icon { font-size: 80px; }
                            h1 { color: #4caf50; }
                            p { color: #aaa; }
                        </style>
                        </head>
                        <body>
                            <div class='icon'>✅</div>
                            <h1>Payment Successful!</h1>
                            <p>{$currency} {$amount} has been added to your wallet.</p>
                            <p>You can now close this window and return to the app.</p>
                        </body>
                        </html>
                    ", 200, ['Content-Type' => 'text/html']);
                }
            } catch (\Exception $e) {
                Log::error('Flutterwave callback verification error: ' . $e->getMessage());
            }
        }

        // Payment failed or cancelled
        $debugReason = "Status: " . ($status ?? 'N/A') . " | Transaction ID: " . ($transactionId ?? 'None');
        if (isset($e)) $debugReason .= " | Verification Error: " . $e->getMessage();
        
        die("DEBUG INFO (READ THIS): Payment Verification Failed. " . $debugReason);

        return response()->make("
            <html>
            <head><title>Payment Status</title>
            <meta name='viewport' content='width=device-width, initial-scale=1'>
            <style>
                body { font-family: system-ui; text-align: center; padding: 40px; background: #0a1929; color: white; }
                .icon { font-size: 80px; }
                h1 { color: #f44336; }
                p { color: #aaa; }
            </style>
            </head>
            <body>
                <div class='icon'>❌</div>
                <h1>Payment Not Completed</h1>
                <p>Your payment was not successful or was cancelled.</p>
                <p>Please close this window and try again.</p>
            </body>
            </html>
        ", 200, ['Content-Type' => 'text/html']);
    }
}
