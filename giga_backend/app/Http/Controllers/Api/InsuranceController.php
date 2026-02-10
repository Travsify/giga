<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Delivery;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class InsuranceController extends Controller
{
    /**
     * Get insurance premium for a delivery.
     */
    public function getPremium(Request $request): JsonResponse
    {
        $request->validate([
            'item_value' => 'required|numeric|min:0',
        ]);

        $premium = $this->calculatePremium($request->item_value);

        return response()->json([
            'success' => true,
            'premium' => $premium,
            'currency' => 'NGN',
            'coverage' => 'Total Loss & Damage'
        ]);
    }

    /**
     * Opt-in for insurance on a delivery.
     */
    public function optIn(Request $request, Delivery $delivery): JsonResponse
    {
        if ($delivery->is_insured) {
            return response()->json(['success' => false, 'message' => 'Delivery is already insured.'], 400);
        }

        $request->validate([
            'insured_value' => 'required|numeric|min:1',
        ]);

        $premium = $this->calculatePremium($request->insured_value);

        \Illuminate\Support\Facades\DB::transaction(function() use ($delivery, $request, $premium) {
            $delivery->update([
                'is_insured' => true,
                'insured_value' => $request->insured_value,
                'insurance_premium' => $premium,
                'insurance_policy_no' => 'GIGA-INS-' . strtoupper(\Illuminate\Support\Str::random(10)),
            ]);

            // Optional: Deduct premium from user wallet if already paid or logic for that
            // $request->user()->wallet->decrement('balance', $premium);
        });

        return response()->json([
            'success' => true,
            'message' => 'Insurance policy generated successfully.',
            'data' => [
                'premium' => $premium,
                'policy_no' => $delivery->insurance_policy_no,
                'insured_value' => $delivery->insured_value
            ]
        ]);
    }

    private function calculatePremium($value)
    {
        // Simple 1% premium for insurance
        return round($value * 0.01, 2);
    }
}
