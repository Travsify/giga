<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Delivery;
use App\Models\DeliveryBid;
use App\Models\Rider;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class BiddingController extends Controller
{
    /**
     * Get bids for a specific delivery.
     */
    public function getBids(Delivery $delivery): JsonResponse
    {
        $bids = $delivery->bids()->with('rider.user')->get();

        return response()->json([
            'success' => true,
            'data' => $bids
        ]);
    }

    /**
     * Place a bid on a delivery (Rider only).
     */
    public function placeBid(Request $request, Delivery $delivery): JsonResponse
    {
        $rider = $request->user()->rider;
        if (!$rider) {
            return response()->json(['success' => false, 'message' => 'Only riders can place bids.'], 403);
        }

        if ($delivery->status !== 'pending') {
            return response()->json(['success' => false, 'message' => 'This delivery is no longer accepting bids.'], 400);
        }

        $validator = Validator::make($request->all(), [
            'bid_amount' => 'required|numeric|min:1',
            'estimated_pickup_time' => 'required|string',
            'notes' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
        }

        $bid = DeliveryBid::updateOrCreate(
            ['delivery_id' => $delivery->id, 'rider_id' => $rider->id],
            [
                'bid_amount' => $request->bid_amount,
                'estimated_pickup_time' => $request->estimated_pickup_time,
                'notes' => $request->notes,
                'status' => 'pending'
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Bid placed successfully.',
            'data' => $bid
        ]);
    }

    /**
     * Accept a bid (Customer only).
     */
    public function acceptBid(Request $request, DeliveryBid $bid): JsonResponse
    {
        $delivery = $bid->delivery;
        if ($delivery->customer_id !== $request->user()->id) {
            return response()->json(['success' => false, 'message' => 'Unauthorized.'], 403);
        }

        \Illuminate\Support\Facades\DB::transaction(function() use ($bid, $delivery) {
            // Update bid status
            $bid->update(['status' => 'accepted']);

            // Reject other bids
            $delivery->bids()->where('id', '!=', $bid->id)->update(['status' => 'rejected']);

            // Update delivery with final fare and rider
            $delivery->update([
                'rider_id' => $bid->rider_id,
                'total_fare' => $bid->bid_amount,
                'status' => 'assigned',
                'assigned_at' => now()
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Bid accepted and rider assigned.',
            'data' => $delivery->fresh(['rider.user'])
        ]);
    }
}
