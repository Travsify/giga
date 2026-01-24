<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Delivery;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SustainabilityController extends Controller
{
    public function getStats(Request $request)
    {
        $user = $request->user();
        
        // Fetch all delivered orders for this user
        $deliveries = Delivery::where('customer_id', $user->id)
            ->where('status', 'delivered')
            ->get();

        $totalDistanceKm = 0;

        foreach ($deliveries as $delivery) {
            if ($delivery->pickup_lat && $delivery->pickup_lng && $delivery->dropoff_lat && $delivery->dropoff_lng) {
                $totalDistanceKm += $this->calculateDistance(
                    $delivery->pickup_lat,
                    $delivery->pickup_lng,
                    $delivery->dropoff_lat,
                    $delivery->dropoff_lng
                );
            }
        }

        // Carbon Calculation: 
        // Average petrol car emits ~120g CO2 per km.
        // Giga (Electric/Bike) assumes 0g tailpipe.
        // Saved = 0.12 kg * km.
        $co2SavedKg = $totalDistanceKm * 0.12;

        return response()->json([
            'total_co2_saved_kg' => round($co2SavedKg, 2),
            'eco_deliveries_count' => $deliveries->count(),
            'distance_cycled_km' => round($totalDistanceKm, 1),
            'paper_saved_sheets' => $deliveries->count() * 5, // Approx 5 sheets per paper waybill
            'trees_equivalent' => round($co2SavedKg / 20, 1) // 1 tree absorbs ~20kg CO2/year
        ]);
    }

    // Haversine Formula
    private function calculateDistance($lat1, $lon1, $lat2, $lon2)
    {
        $earthRadius = 6371; // km

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }
}
