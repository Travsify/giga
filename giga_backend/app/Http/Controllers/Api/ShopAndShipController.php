<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class ShopAndShipController extends Controller
{
    /**
     * Get international shipping addresses for the user
     */
    public function getAddress(Request $request): JsonResponse
    {
        $user = $request->user();
        $userTag = 'GIGA-' . strtoupper(substr($user->name, 0, 3)) . $user->id;

        return response()->json([
            'success' => true,
            'data' => [
                'uk_address' => [
                    'line_1' => 'Giga Logistics Hub, Unit 5',
                    'line_2' => 'Industrial Park (' . $userTag . ')',
                    'city' => 'London',
                    'postcode' => 'E1 6AN',
                    'country' => 'United Kingdom',
                ],
                'us_address' => [
                    'line_1' => '123 Giga Way',
                    'line_2' => 'Suite 400 (' . $userTag . ')',
                    'city' => 'Houston',
                    'state' => 'TX',
                    'postcode' => '77002',
                    'country' => 'USA',
                ]
            ]
        ]);
    }

    /**
     * Get user's international packages
     */
    public function getPackages(Request $request): JsonResponse
    {
        // Mock data for packages in transit to Nigeria
        return response()->json([
            'success' => true,
            'data' => [
                [
                    'id' => 1,
                    'origin' => 'London, UK',
                    'status' => 'at_hub',
                    'description' => 'Electronics',
                    'tracking_no' => 'GIGA-UK-7721',
                    'created_at' => now()->subDays(2)->toIso8601String(),
                ],
                [
                    'id' => 2,
                    'origin' => 'Houston, USA',
                    'status' => 'in_transit',
                    'description' => 'Clothing',
                    'tracking_no' => 'GIGA-US-4412',
                    'created_at' => now()->subDays(5)->toIso8601String(),
                ]
            ]
        ]);
    }
}
