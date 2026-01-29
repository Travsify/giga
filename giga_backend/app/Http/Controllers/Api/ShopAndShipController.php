<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\WarehousePackage;
use Illuminate\Support\Str;

class ShopAndShipController extends Controller
{
    public function getAddress(Request $request)
    {
        $user = $request->user();

        // Generate ID if missing (Lazy Generation)
        if (!$user->suite_number) {
            $user->suite_number = 'GGA-' . str_pad($user->id, 5, '0', STR_PAD_LEFT);
            $user->save();
        }

        return response()->json([
            'unit' => 'Unit 5, Giga Warehouse',
            'street' => '123 Logistics Way', // Example address
            'city' => 'London',
            'postcode' => 'NW10 6RF',
            'country' => 'United Kingdom',
            'suite_number' => $user->suite_number, // The vital part
            'full_address_text' => "{$user->name}\nUnit 5, Giga Warehouse\nSuite #{$user->suite_number}\n123 Logistics Way\nLondon, NW10 6RF\nUnited Kingdom"
        ]);
    }

    public function getPackages(Request $request)
    {
        $packages = WarehousePackage::where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($packages);
    }
    
    // Admin only - For testing/demo purposes
    public function createPackage(Request $request) 
    {
        // Find user by suite_number
        $suite = $request->input('suite_number');
        if (!$suite) return response()->json(['error' => 'Suite required'], 400);
        
        $user = \App\Models\User::where('suite_number', $suite)->first();
        if (!$user) return response()->json(['error' => 'User not found'], 404);
        
        $pkg = WarehousePackage::create([
            'user_id' => $user->id,
            'tracking_number' => $request->input('tracking_number', 'TRK'.rand(1000,9999)),
            'carrier' => $request->input('carrier', 'Amazon'),
            'weight_kg' => $request->input('weight_kg', 1.5),
            'description' => $request->input('description', 'Box from Amazon'),
            'status' => 'received',
            'shipping_fee' => 10.00, // Mock calculation
        ]);
        
        return response()->json($pkg);
    }
}
