<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class InterStateController extends Controller
{
    /**
     * Get estimated price for inter-state delivery
     */
    public function getPrice(Request $request): JsonResponse
    {
        $request->validate([
            'origin_city' => 'required|string',
            'destination_city' => 'required|string',
            'weight_kg' => 'required|numeric|min:0.1',
            'parcel_type' => 'required|string',
        ]);

        // Mock logic for pricing based on distance/weight
        // In production, this would look up a rate table
        $baseRate = 5000; // Base ₦5,000 for inter-state
        $weightSurcharge = ($request->weight_kg - 1) * 500;
        $totalFare = $baseRate + max(0, $weightSurcharge);

        return response()->json([
            'success' => true,
            'data' => [
                'origin' => $request->origin_city,
                'destination' => $request->destination_city,
                'estimated_fare' => $totalFare,
                'currency' => 'NGN',
                'delivery_time_days' => '2-3 days',
            ]
        ]);
    }

    /**
     * Create an inter-state waybill/request
     */
    public function createWaybill(Request $request): JsonResponse
    {
        $request->validate([
            'sender_name' => 'required|string',
            'sender_phone' => 'required|string',
            'receiver_name' => 'required|string',
            'receiver_phone' => 'required|string',
            'pickup_address' => 'required|string',
            'delivery_address' => 'required|string',
            'parcel_description' => 'required|string',
            'weight_kg' => 'required|numeric',
        ]);

        $trackingNumber = 'GIGA-IS-' . strtoupper(bin2hex(random_bytes(4)));

        return response()->json([
            'success' => true,
            'message' => 'Inter-state waybill created successfully',
            'data' => [
                'tracking_number' => $trackingNumber,
                'status' => 'pending_pickup',
                'estimated_delivery' => now()->addDays(3)->toDateString(),
            ]
        ], 201);
    }
}
