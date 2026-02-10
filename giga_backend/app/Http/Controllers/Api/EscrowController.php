<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Delivery;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class EscrowController extends Controller
{
    /**
     * Initiate escrow for a delivery.
     */
    public function initiateEscrow(Delivery $delivery): JsonResponse
    {
        if ($delivery->is_escrow) {
            return response()->json(['success' => false, 'message' => 'Escrow already initiated.'], 400);
        }

        $delivery->update([
            'is_escrow' => true,
            'escrow_status' => 'pending',
            'escrow_pin' => strtoupper(Str::random(6)), // Secure 6-digit alphanum PIN
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Escrow initiated. Share the PIN only when delivery is verified.',
            'pin' => $delivery->escrow_pin
        ]);
    }

    /**
     * Release escrow payment (Rider submits PIN provided by Customer).
     */
    public function releaseEscrow(Request $request, Delivery $delivery): JsonResponse
    {
        $request->validate(['pin' => 'required|string']);

        if ($delivery->escrow_pin !== strtoupper($request->pin)) {
            return response()->json(['success' => false, 'message' => 'Invalid Escrow PIN.'], 422);
        }

        if ($delivery->escrow_status !== 'pending') {
            return response()->json(['success' => false, 'message' => 'Escrow is not in pending state.'], 400);
        }

        DB::transaction(function () use ($delivery) {
            $delivery->update([
                'escrow_status' => 'released',
                'status' => 'delivered'
            ]);

            // Logic to transfer funds from Escrow/Admin wallet to Rider's wallet
            $riderUser = $delivery->rider->user;
            
            if (!$riderUser->wallet) {
                throw new \Exception('Rider wallet not found.');
            }

            $riderUser->wallet->increment('balance', $delivery->total_fare);
            
            // Log transaction
            $riderUser->transactions()->create([
                'amount' => $delivery->total_fare,
                'type' => 'credit',
                'description' => "Escrow released for Delivery #{$delivery->id}",
                'currency' => $delivery->currency_code ?? 'NGN',
                'category' => 'delivery_earnings'
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Escrow released successfully. Funds transferred to rider wallet.'
        ]);
    }

    /**
     * Dispute an escrow delivery.
     */
    public function disputeEscrow(Delivery $delivery): JsonResponse
    {
        $delivery->update(['escrow_status' => 'disputed']);

        return response()->json([
            'success' => true,
            'message' => 'Escrow disputed. Support will contact both parties.'
        ]);
    }
}
