<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class SubscriptionController extends Controller
{
    /**
     * Get current subscription status.
     */
    public function status()
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();
        
        return response()->json([
            'is_giga_plus' => (bool) $user->is_giga_plus,
            'expiry' => $user->giga_plus_expiry ? $user->giga_plus_expiry->toDateTimeString() : null,
            'days_left' => $user->giga_plus_expiry ? Carbon::now()->diffInDays($user->giga_plus_expiry, false) : 0,
        ]);
    }

    /**
     * Subscribe to Giga+ using Wallet or External Payment.
     */
    public function subscribe(Request $request)
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();
        
        // Subscription Price
        $price = 39.99; // GBP default
        $currencyCode = 'GBP';

        if ($user->country_code === 'NG') {
            $price = 80000; // Fixed Naira price for Nigeria
            $currencyCode = 'NGN';
        }

        // Check if user wants to use wallet
        if ($request->has('use_wallet') && $request->use_wallet) {
            $wallet = $user->wallet;
            
            if (!$wallet || $wallet->balance < $price) {
                return response()->json([
                    'error' => 'Insufficient wallet balance. Please top up your wallet first.',
                    'required_amount' => $price,
                    'current_balance' => $wallet ? $wallet->balance : 0
                ], 400);
            }

            // Deduct from wallet
            return \Illuminate\Support\Facades\DB::transaction(function () use ($user, $wallet, $price, $currencyCode) {
                $wallet->decrement('balance', $price);

                // Record Transaction
                $wallet->transactions()->create([
                    'amount' => $price,
                    'type' => 'debit',
                    'description' => 'Giga+ Premium Subscription',
                    'reference' => 'SUB_' . strtoupper(\Illuminate\Support\Str::random(10)),
                    'status' => 'completed',
                    'currency' => $currencyCode,
                ]);

                // Activate Subscription
                $user->is_giga_plus = true;
                $baseDate = ($user->giga_plus_expiry && $user->giga_plus_expiry->isFuture()) 
                    ? $user->giga_plus_expiry 
                    : Carbon::now();
                $user->giga_plus_expiry = $baseDate->addDays(30);
                $user->save();

                return response()->json([
                    'success' => true,
                    'message' => 'Subscription active! Deducted from your wallet.',
                    'balance' => $wallet->balance,
                    'expiry' => $user->giga_plus_expiry->toDateTimeString(),
                ]);
            });
        }

        // If not using wallet (direct checkout flow completed)
        $user->is_giga_plus = true;
        $baseDate = ($user->giga_plus_expiry && $user->giga_plus_expiry->isFuture()) 
            ? $user->giga_plus_expiry 
            : Carbon::now();
        $user->giga_plus_expiry = $baseDate->addDays(30);
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Welcome to Giga+! Your subscription is active.',
            'is_giga_plus' => true,
            'expiry' => $user->giga_plus_expiry->toDateTimeString(),
        ]);
    }

    /**
     * Cancel / Resume (Logic placeholder for real subscriptions)
     */
    public function cancel(Request $request)
    {
        $user = $request->user();
        
        $user->is_giga_plus = false;
        // Don't clear expiry so they keep benefits until date
        // But for mock assume immediate cancellation effect on auto-renewal
        $user->save();

        return response()->json([
            'message' => 'Subscription cancelled successfully. Benefits will remain active until expiry.',
            'is_giga_plus' => false,
            'expiry' => $user->giga_plus_expiry ? $user->giga_plus_expiry->toDateTimeString() : null
        ]);
    }
}
