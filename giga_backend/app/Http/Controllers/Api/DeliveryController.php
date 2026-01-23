<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Delivery;
use App\Models\Rider;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class DeliveryController extends Controller
{
    public function estimateFare(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'pickup_lat' => 'required|numeric',
            'pickup_lng' => 'required|numeric',
            'dropoff_lat' => 'required|numeric',
            'dropoff_lng' => 'required|numeric',
            'vehicle_type' => 'required|in:Bike,Van,Truck',
            'service_tier' => 'required|in:Standard,Priority,Saver',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $distance = $this->calculateDistance(
            $request->pickup_lat,
            $request->pickup_lng,
            $request->dropoff_lat,
            $request->dropoff_lng
        );

        // UK Pricing in £
        $baseFare = match($request->vehicle_type) {
            'Bike' => 3.00,
            'Van' => 8.00,
            'Truck' => 25.00,
        };

        $distanceFare = $distance * 1.50; // £1.50 per km

        $tierMultiplier = match($request->service_tier) {
            'Standard' => 1.0,
            'Priority' => 1.5,
            'Saver' => 0.8,
        };

        $totalFare = ($baseFare + $distanceFare) * $tierMultiplier;

        // Giga+ Benefit: £0 Delivery fee (Standard/Saver tiers) 
        // We'll calculate the discount if the user is a premium member.
        $user = $request->user();
        $isGigaPlus = $user && (bool) $user->is_giga_plus;
        
        $discount = 0;
        if ($isGigaPlus && in_array($request->service_tier, ['Standard', 'Saver'])) {
            $discount = $totalFare; // Fully waive the fee
        }

        return response()->json([
            'distance_km' => round($distance, 2),
            'estimated_total' => round($totalFare, 2),
            'discount' => round($discount, 2),
            'final_fare' => round(max(0, $totalFare - $discount), 2),
            'currency' => 'GBP',
            'is_giga_plus' => $isGigaPlus,
        ]);
    }

    public function create(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'parcel_type' => 'required|string',
            'description' => 'nullable|string',
            'pickup_address' => 'required|string',
            'pickup_lat' => 'required|numeric',
            'pickup_lng' => 'required|numeric',
            'dropoff_address' => 'required|string',
            'dropoff_lat' => 'required|numeric',
            'dropoff_lng' => 'required|numeric',
            'vehicle_type' => 'required|string',
            'service_tier' => 'required|string',
            'fare' => 'required|numeric',
            'contactless_delivery' => 'boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $delivery = Delivery::create([
            'customer_id' => $request->user()->id,
            'parcel_type' => $request->parcel_type,
            'description' => $request->description,
            'pickup_address' => $request->pickup_address,
            'pickup_lat' => $request->pickup_lat,
            'pickup_lng' => $request->pickup_lng,
            'dropoff_address' => $request->dropoff_address,
            'dropoff_lat' => $request->dropoff_lat,
            'dropoff_lng' => $request->dropoff_lng,
            'vehicle_type' => $request->vehicle_type,
            'service_tier' => $request->service_tier,
            'fare' => $request->fare,
            'status' => 'pending',
            'contactless_delivery' => $request->contactless_delivery ?? false,
        ]);

        return response()->json($delivery, 201);
    }

    public function getNearbyRiders(Request $request)
    {
        $lat = $request->query('lat');
        $lng = $request->query('lng');
        $radius = $request->query('radius', 5); // 5km default

        $riders = Rider::where('is_online', true)
            ->whereNotNull('current_lat')
            ->whereNotNull('current_lng')
            ->get()
            ->filter(function ($rider) use ($lat, $lng, $radius) {
                $distance = $this->calculateDistance(
                    $lat,
                    $lng,
                    $rider->current_lat,
                    $rider->current_lng
                );
                return $distance <= $radius;
            });

        return response()->json($riders->values());
    }

    public function updateStatus(Request $request, $id)
    {
        $delivery = Delivery::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'status' => 'sometimes|in:pending,assigned,picked_up,in_transit,delivered,cancelled',
            'contactless_delivery' => 'sometimes|boolean',
            'locker_id' => 'sometimes|string',
            'locker_code' => 'sometimes|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        if ($request->has('status')) {
            $delivery->status = $request->status;
        }

        if ($request->has('contactless_delivery')) {
            $delivery->contactless_delivery = $request->contactless_delivery;
        }

        if ($request->has('locker_id')) {
            $delivery->locker_id = $request->locker_id;
        }

        if ($request->has('locker_code')) {
            $delivery->locker_code = $request->locker_code;
        }

        if ($request->status === 'picked_up') {
            $delivery->picked_up_at = now();
        } elseif ($request->status === 'delivered') {
            $delivery->delivered_at = now();
        }

        $delivery->save();

        return response()->json($delivery);
    }

    private function calculateDistance($lat1, $lon1, $lat2, $lon2)
    {
        $earthRadius = 6371; // km

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat/2) * sin($dLat/2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon/2) * sin($dLon/2);

        $c = 2 * atan2(sqrt($a), sqrt(1-$a));

        return $earthRadius * $c;
    }

    public function uploadProof(Request $request, $id)
    {
        $delivery = Delivery::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'proof_image' => 'required|image|max:5120', // Max 5MB
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        if ($request->hasFile('proof_image')) {
            $path = $request->file('proof_image')->store('proofs', 'public');
            // Assuming storage link is set up: php artisan storage:link
            $url = asset('storage/' . $path);
            
            $delivery->proof_of_delivery_url = $url;
            $delivery->save();

            return response()->json(['url' => $url]);
        }

        return response()->json(['error' => 'File upload failed'], 500);
    }
}
