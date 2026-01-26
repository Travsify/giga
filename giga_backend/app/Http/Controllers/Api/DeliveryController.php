<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Delivery;
use App\Models\Rider;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class DeliveryController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $query = Delivery::where('customer_id', $user->id);

        if ($request->has('status')) {
            $statuses = explode(',', $request->status);
            $query->whereIn('status', $statuses);
        }

        $deliveries = $query->orderBy('created_at', 'desc')->get();

        return response()->json($deliveries);
    }

    public function estimateFare(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'pickup_lat' => 'required|numeric',
            'pickup_lng' => 'required|numeric',
            'dropoff_lat' => 'required|numeric',
            'dropoff_lng' => 'required|numeric',
            'vehicle_type' => 'required|in:Bike,Van,Truck',
            'service_tier' => 'required|in:Standard,Priority,Saver,Expo',
            'parcel_size' => 'nullable|string',
            'parcel_category' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $stops = $request->stops;
        if (empty($stops) || count($stops) < 2) {
            return response()->json(['error' => 'At least two stops (pickup and dropoff) are required.'], 422);
        }

        $totalDistance = 0;
        for ($i = 0; $i < count($stops) - 1; $i++) {
            $totalDistance += $this->calculateDistance(
                $stops[$i]['lat'],
                $stops[$i]['lng'],
                $stops[$i+1]['lat'],
                $stops[$i+1]['lng']
            );
        }

        $distance = $totalDistance;

        // UK Pricing in £
        $baseFare = match($request->vehicle_type) {
            'Bike' => 3.00,
            'Van' => 12.00, // Adjusted for UK market
            'Truck' => 35.00, // Adjusted for UK market
        };

        $distanceRate = match($request->vehicle_type) {
            'Bike' => 0.80,
            'Van' => 1.50,
            'Truck' => 2.50,
        };

        $distanceFare = $distance * $distanceRate;

        // Size Multipliers
        $sizeMultiplier = match($request->parcel_size) {
            'Letter' => 0.8,
            'Box' => 1.0,
            'Medium' => 1.2,
            'Large' => 1.5,
            'Van Load' => 2.5,
            default => 1.0,
        };

        // Category Surcharges
        $categorySurcharge = match($request->parcel_category) {
            'Fragile' => 5.00,
            'Electronics' => 3.00,
            'Hazardous' => 25.00, // Safety surcharge
            default => 0.00,
        };

        $tierMultiplier = match($request->service_tier) {
            'Standard' => 1.0,
            'Priority', 'Expo' => 1.4,
            'Saver' => 0.85,
        };

        // Multi-stop surcharge: £3.00 per extra stop (after the first two)
        $stopCharge = max(0, (count($stops) - 2) * 3.00);

        $totalFare = (($baseFare + $distanceFare) * $sizeMultiplier * $tierMultiplier) + $categorySurcharge + $stopCharge;

        // Giga+ Benefit: Wave base fee or percentage discount
        $user = $request->user();
        $isGigaPlus = $user && (bool) $user->is_giga_plus;
        
        $discount = 0;
        if ($isGigaPlus) {
            if (in_array($request->service_tier, ['Standard', 'Saver'])) {
                $discount = $totalFare * 0.25; // 25% discount for Giga+ members
            }
        }

        return response()->json([
            'distance_km' => round($distance, 2),
            'estimated_total' => round($totalFare, 2),
            'discount' => round($discount, 2),
            'final_fare' => round(max(3.50, $totalFare - $discount), 2), // Minimum UK fare £3.50
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

        if ($request->has('stops')) {
            foreach ($request->stops as $index => $stop) {
                $delivery->stops()->create([
                    'address' => $stop['address'],
                    'lat' => $stop['lat'],
                    'lng' => $stop['lng'],
                    'stop_order' => $index,
                    'type' => $stop['type'] ?? ($index === 0 ? 'pickup' : 'dropoff'),
                    'instructions' => $stop['instructions'] ?? null,
                ]);
            }
        }

        return response()->json($delivery->load('stops'), 201);
    }

    public function getNearbyRiders(Request $request)
    {
        $lat = $request->query('lat');
        $lng = $request->query('lng');
        $radius = $request->query('radius', 5); // 5km default
        $user = $request->user();

        // STRICT GEOLOCATION: Filter by country_code
        // Riders should only be visible if they are in the same country as the user requesting
        // or if explicitly filtered by country (if valid use case).
        $countryCode = $user ? $user->country_code : $request->query('country_code');

        $query = Rider::where('is_online', true)
            ->whereNotNull('current_lat')
            ->whereNotNull('current_lng');

        if ($countryCode) {
            // Assuming Rider has 'country_code' or we check via relationship to User
            // Ideally Rider table has country_code. If not, check via user relationship.
            // For now, let's assume we can filter by querying the related user's country
            $query->whereHas('user', function($q) use ($countryCode) {
                $q->where('country_code', $countryCode);
            });
        }

        $riders = $query->get()
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
