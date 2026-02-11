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
     * Subscribe to Giga+ (Mock payment integration).
     */
    public function subscribe(Request $request)
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        // 1. Get Giga+ Price (default 39.99 GBP)
        $basePrice = \App\Models\AppSetting::get('giga_plus_price_gbp', 39.99);
        $rate = \App\Models\AppSetting::get('ngn_exchange_rate', 2000.0);
        
        $isNG = $user->country_code === 'NG';
        $finalAmount = $isNG ? ($basePrice * $rate) : $basePrice;
        $currency = $isNG ? 'NGN' : 'GBP';

        // 2. Check Wallet
        $wallet = $user->wallet;
        if (!$wallet || $wallet->balance < $finalAmount) {
             return response()->json([
                 'error' => 'Insufficient funds in your Giga Wallet. Please top up to join Giga+.'
             ], 400);
        }

        // 3. Deduct Funds & Activate
        try {
            return \Illuminate\Support\Facades\DB::transaction(function () use ($user, $wallet, $finalAmount, $currency) {
                $wallet->balance = (double) $wallet->balance - (double) $finalAmount;
                $wallet->save();

                // Record Transaction
                $wallet->transactions()->create([
                    'amount' => -$finalAmount,
                    'type' => 'debit',
                    'description' => 'Giga+ Membership Subscription',
                    'reference' => 'SUB_' . time() . '_' . $user->id,
                    'status' => 'completed',
                    'currency' => $currency,
                    'category' => 'subscription'
                ]);

                // Activate Membership
                $user->is_giga_plus = true;
                $baseDate = ($user->giga_plus_expiry && $user->giga_plus_expiry->isFuture()) 
                    ? $user->giga_plus_expiry 
                    : \Carbon\Carbon::now();
                    
                $user->giga_plus_expiry = $baseDate->addDays(30);
                $user->save();

                return response()->json([
                    'message' => 'Welcome to Giga+! Your subscription is active.',
                    'is_giga_plus' => true,
                    'expiry' => $user->giga_plus_expiry->toDateTimeString(),
                    'new_balance' => $wallet->balance
                ]);
            });
        } catch (\Exception $e) {
            return response()->json(['error' => 'Failed to process subscription: ' . $e->getMessage()], 500);
        }
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
