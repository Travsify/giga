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
        
        $deliveries = Delivery::where('customer_id', $user->id)
            ->where('status', 'delivered')
            ->get();

        $totalDistanceKm = 0;
        $greenDistanceKm = 0;

        foreach ($deliveries as $delivery) {
            if ($delivery->pickup_lat && $delivery->pickup_lng && $delivery->dropoff_lat && $delivery->dropoff_lng) {
                $dist = $this->calculateDistance(
                    $delivery->pickup_lat,
                    $delivery->pickup_lng,
                    $delivery->dropoff_lat,
                    $delivery->dropoff_lng
                );
                $totalDistanceKm += $dist;
                
                if (in_array($delivery->green_choice, ['ev', 'bicycle'])) {
                    $greenDistanceKm += $dist;
                }
            }
        }

        $co2SavedKg = $totalDistanceKm * 0.12;
        $extraGreenSavings = $greenDistanceKm * 0.05; 

        return response()->json([
            'total_co2_saved_kg' => round($co2SavedKg + $extraGreenSavings, 2),
            'eco_deliveries_count' => $deliveries->count(),
            'distance_cycled_km' => round($totalDistanceKm, 1),
            'green_choice_distance_km' => round($greenDistanceKm, 1),
            'paper_saved_sheets' => $deliveries->count() * 5,
            'trees_equivalent' => round(($co2SavedKg + $extraGreenSavings) / 20, 1),
            'social_badge' => $this->getBadge($totalDistanceKm),
        ]);
    }

    private function getBadge($distance)
    {
        if ($distance > 500) return 'Giga Legend';
        if ($distance > 100) return 'Eco Warrior';
        if ($distance > 10) return 'Green Starter';
        return 'Seedling';
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
