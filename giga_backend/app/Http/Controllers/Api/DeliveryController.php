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
            'service_type' => 'required|in:bike,van,truck',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Simple distance calculation (Haversine formula)
        $distance = $this->calculateDistance(
            $request->pickup_lat,
            $request->pickup_lng,
            $request->dropoff_lat,
            $request->dropoff_lng
        );

        // Base fare calculation
        $baseFare = match($request->service_type) {
            'bike' => 500,
            'van' => 1500,
            'truck' => 5000,
        };

        $fare = $baseFare + ($distance * 100); // ₦100 per km

        return response()->json([
            'distance_km' => round($distance, 2),
            'estimated_fare' => round($fare, 2),
            'service_type' => $request->service_type,
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
            'fare' => 'required|numeric',
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
            'fare' => $request->fare,
            'status' => 'pending',
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
            'status' => 'required|in:pending,assigned,picked_up,in_transit,delivered,cancelled',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $delivery->status = $request->status;

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
}
