<?php

namespace App\Services;

use Stripe\Stripe;
use Stripe\Payout;
use Illuminate\Support\Facades\Log;

class StripePayoutService
{
    public function __construct()
    {
        Stripe::setApiKey(env('STRIPE_SECRET'));
    }

    /**
     * Initiate a payout to a bank account or debit card.
     * Note: In a real production app, you'd typically use Stripe Connect
     * and create Payouts for connected accounts.
     */
    public function initiatePayout($amount, $currency = 'gbp', $description = 'Giga Rider Payout')
    {
        try {
            // For demo/simulated production, we assume the account is already linked
            // or we're using the standard platform payout.
            $payout = Payout::create([
                'amount' => $amount * 100, // cents
                'currency' => $currency,
                'statement_descriptor' => 'GIGA PAYOUT',
                'description' => $description,
            ]);

            return [
                'success' => true,
                'data' => $payout
            ];

        } catch (\Exception $e) {
            Log::error('Stripe Payout Exception: ' . $e->getMessage());
            return [
                'success' => false,
                'message' => $e->getMessage()
            ];
        }
    }
}
