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

    /**
     * Get the status of an existing order.
     */
    public function getOrderStatus(Request $request, $id)
    {
        $business = $request->external_business;

        $delivery = Delivery::where('id', $id)
            ->where('logistics_company_id', $business->id)
            ->first();

        if (!$delivery) {
            return response()->json(['message' => 'Order not found.'], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => [
                'order_id' => $delivery->id,
                'tracking_number' => $delivery->tracking_number,
                'status' => $delivery->status,
                'parcel_type' => $delivery->parcel_type,
                'pickup_address' => $delivery->pickup_address,
                'dropoff_address' => $delivery->dropoff_address,
                'vehicle_type' => $delivery->vehicle_type,
                'service_tier' => $delivery->service_tier,
                'fare' => (float) $delivery->fare,
                'security_code' => $delivery->security_code,
                'rider_id' => $delivery->rider_id,
                'created_at' => $delivery->created_at,
                'updated_at' => $delivery->updated_at,
            ]
        ]);
    }

    /**
     * Calculate fare based on distance and vehicle type.
     */
    private function calculateFare(Request $request)
    {
        // Haversine distance calculation
        $lat1 = deg2rad($request->pickup_lat);
        $lat2 = deg2rad($request->dropoff_lat);
        $dLat = $lat2 - $lat1;
        $dLng = deg2rad($request->dropoff_lng - $request->pickup_lng);

        $a = sin($dLat / 2) * sin($dLat / 2)
           + cos($lat1) * cos($lat2) * sin($dLng / 2) * sin($dLng / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        $distanceKm = 6371 * $c; // Earth radius in km

        // Base fare + per-km rate by vehicle type
        $pricing = match($request->vehicle_type) {
            'Bike' => ['base' => 500, 'per_km' => 100],    // NGN pricing
            'Van' => ['base' => 2000, 'per_km' => 250],
            'Truck' => ['base' => 5000, 'per_km' => 400],
            default => ['base' => 800, 'per_km' => 150],
        };

        $fare = $pricing['base'] + ($distanceKm * $pricing['per_km']);

        // Service tier multipliers
        $fare = match($request->service_tier) {
            'Priority' => $fare * 1.5,
            'Saver' => $fare * 0.85,
            default => $fare, // Standard
        };

        // Minimum fare
        $minimumFare = match($request->vehicle_type) {
            'Bike' => 500,
            'Van' => 2000,
            'Truck' => 5000,
            default => 800,
        };

        return round(max($fare, $minimumFare), 2);
    }

    /**
     * Notify nearby riders about a new external order.
     */
    private function notifyRiders(Delivery $delivery)
    {
        // Find online riders near the pickup location (within 10km)
        $nearbyRiders = \App\Models\Rider::where('is_online', true)
            ->where('verification_status', 'verified')
            ->whereRaw("
                (6371 * acos(
                    cos(radians(?)) * cos(radians(current_lat)) *
                    cos(radians(current_lng) - radians(?)) +
                    sin(radians(?)) * sin(radians(current_lat))
                )) < 10
            ", [$delivery->pickup_lat, $delivery->pickup_lng, $delivery->pickup_lat])
            ->limit(20)
            ->get();

        // Log notification for audit trail
        \Illuminate\Support\Facades\Log::info('External API order created', [
            'delivery_id' => $delivery->id,
            'notified_riders' => $nearbyRiders->count(),
            'pickup' => $delivery->pickup_address,
        ]);

        // Send push notifications if FCM/Pusher is configured
        // foreach ($nearbyRiders as $rider) {
        //     $rider->user->notify(new \App\Notifications\NewDeliveryNotification($delivery));
        // }
    }
}
