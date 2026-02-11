<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Delivery;
use App\Models\LogisticsCompany;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class ExternalOrderController extends Controller
{
    /**
     * Create a new delivery/pickup order via API Key.
     */
    public function createOrder(Request $request)
    {
        $business = $request->external_business;

        $validator = Validator::make($request->all(), [
            'parcel_type' => 'required|string',
            'description' => 'nullable|string',
            'pickup_address' => 'required|string',
            'pickup_lat' => 'required|numeric',
            'pickup_lng' => 'required|numeric',
            'dropoff_address' => 'required|string',
            'dropoff_lat' => 'required|numeric',
            'dropoff_lng' => 'required|numeric',
            'vehicle_type' => 'required|in:Bike,Van,Truck',
            'service_tier' => 'required|in:Standard,Priority,Saver',
            'recipient_phone' => 'required|string',
            'external_reference' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Automatic fare calculation or based on business contract
        // For simplicity, we use a basic calculation here
        $fare = $this->calculateFare($request);

        $delivery = Delivery::create([
            'customer_id' => $business->user_id, // Link to the owner of the business
            'logistics_company_id' => $business->id,
            'parcel_type' => $request->parcel_type,
            'description' => $request->description . ($request->external_reference ? " (Ref: {$request->external_reference})" : ""),
            'pickup_address' => $request->pickup_address,
            'pickup_lat' => $request->pickup_lat,
            'pickup_lng' => $request->pickup_lng,
            'dropoff_address' => $request->dropoff_address,
            'dropoff_lat' => $request->dropoff_lat,
            'dropoff_lng' => $request->dropoff_lng,
            'vehicle_type' => $request->vehicle_type,
            'service_tier' => $request->service_tier,
            'fare' => $fare,
            'status' => 'pending',
            'recipient_phone' => $request->recipient_phone,
            'security_code' => strtoupper(Str::random(6)),
            'service_category' => 'external_api',
        ]);

        // Logic to notify riders (Giga Riders)
        // In a real app, this would trigger a Pusher/Firebase event
        $this->notifyRiders($delivery);

        return response()->json([
            'status' => 'success',
            'message' => 'Order placed successfully. Giga riders have been notified.',
            'data' => [
                'order_id' => $delivery->id,
                'tracking_number' => $delivery->tracking_number, // Assumes Delivery model has tracking_number logic
                'fare' => $fare,
                'status' => $delivery->status,
                'security_code' => $delivery->security_code,
            ]
        ], 201);
    }

    private function calculateFare(Request $request)
    {
        // Simple placeholder fare logic
        $base = match($request->vehicle_type) {
            'Bike' => 5.0,
            'Van' => 15.0,
            'Truck' => 40.0,
            default => 10.0
        };

        if ($request->service_tier === 'Priority') $base *= 1.5;
        
        return $base;
    }

    private function notifyRiders(Delivery $delivery)
    {
        // Integration point for notification system
        // e.g. Notification::send($nearbyRiders, new NewExternalOrderNotification($delivery));
    }
}
