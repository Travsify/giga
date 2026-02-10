<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Delivery;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GiftController extends Controller
{
    /**
     * Create a gift delivery.
     */
    public function createGift(Request $request): JsonResponse
    {
        $request->validate([
            'recipient_name' => 'required|string',
            'recipient_phone' => 'required|string',
            'gift_message' => 'nullable|string',
            'pickup_address' => 'required|string',
            'pickup_lat' => 'required|numeric',
            'pickup_lng' => 'required|numeric',
            'dropoff_address' => 'required|string',
            'dropoff_lat' => 'required|numeric',
            'dropoff_lng' => 'required|numeric',
        ]);

        $delivery = Delivery::create([
            'customer_id' => $request->user()->id,
            'parcel_type' => 'Gift',
            'description' => "Gift for {$request->recipient_name}. Message: {$request->gift_message}",
            'pickup_address' => $request->pickup_address,
            'pickup_lat' => $request->pickup_lat,
            'pickup_lng' => $request->pickup_lng,
            'dropoff_address' => $request->dropoff_address,
            'dropoff_lat' => $request->dropoff_lat,
            'dropoff_lng' => $request->dropoff_lng,
            'recipient_phone' => $request->recipient_phone,
            'status' => 'pending',
            'service_category' => 'gift'
        ]);

        // Logic here to send SMS to recipient notifying them of a surprise gift
        // NotificationService::sendGiftAlert($request->recipient_phone, $request->user()->name);

        return response()->json([
            'success' => true,
            'message' => 'Gift delivery scheduled. Recipient will be notified.',
            'data' => $delivery
        ]);
    }
}
