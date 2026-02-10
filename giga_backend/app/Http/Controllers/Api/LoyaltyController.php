<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LoyaltyController extends Controller
{
    /**
     * Reward user for bill payment activity.
     */
    public function rewardBillPayment(Request $request): JsonResponse
    {
        $user = $request->user();
        $rewardAmount = 50.00; // ₦50 credit per bill payment

        DB::transaction(function() use ($user, $rewardAmount) {
            $user->wallet->increment('balance', $rewardAmount);
            
            $user->transactions()->create([
                'amount' => $rewardAmount,
                'type' => 'credit',
                'description' => 'Logistics Credit (Bill Payment Reward)',
                'currency' => 'NGN'
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => "Loyalty reward of ₦{$rewardAmount} applied to your wallet.",
        ]);
    }
}
