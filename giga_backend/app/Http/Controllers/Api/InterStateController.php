<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\InterStatePrice;
use App\Models\Delivery; // Assuming we reuse Delivery model
use App\Models\Locker;
use Illuminate\Support\Str;

class InterStateController extends Controller
{
    public function getPrice(Request $request)
    {
        $request->validate([
            'origin_state' => 'required|string',
            'destination_state' => 'required|string',
            'size' => 'required|in:Small,Medium,Large',
        ]);

        $route = InterStatePrice::where('origin_state', $request->origin_state)
            ->where('destination_state', $request->destination_state)
            ->first();

        if (!$route) {
            return response()->json(['message' => 'Route not available yet.'], 404);
        }

        $price = $route->base_price;
        if ($request->size === 'Medium') $price += $route->medium_surcharge;
        if ($request->size === 'Large') $price += $route->large_surcharge;

        return response()->json([
            'price' => $price,
            'currency' => 'NGN', // Assuming NG context for now
            'delivery_days' => $route->delivery_days,
        ]);
    }

    public function createWaybill(Request $request)
    {
        $request->validate([
            'origin_locker_id' => 'required|exists:lockers,id',
            'destination_locker_id' => 'required|exists:lockers,id',
            'size' => 'required|in:Small,Medium,Large',
            'recipient_name' => 'required|string',
            'recipient_phone' => 'required|string',
            'items_description' => 'required|string',
            'value' => 'required|numeric',
        ]);

        $user = $request->user();
        
        // 1. Calculate Price again to be safe
        $originLocker = Locker::find($request->origin_locker_id);
        $destLocker = Locker::find($request->destination_locker_id);
        
        // Extract state from locker address (Simplification: We need state in Locker model or derive it)
        // For now, let's assume client passes state or we infer it. 
        // BETTER: Client passes states in the request for pricing, we should probably pass them here too or look them up.
        // Let's assume we pass states for simplicity or I look up locker->address string? 
        // Let's rely on client passing states for now to match `getPrice`.
        
        $price = 0;
        // In a real app, we'd look up the route based on lockers. 
        // For MVP, allow client to pass price OR re-calculate if we have state data.
        // Let's trust the price passed or re-calc if states are provided.
        // Re-calcing is safer. Let's require states.

        $request->validate([
            'origin_state' => 'required|string',
            'destination_state' => 'required|string',
        ]);

        $route = InterStatePrice::where('origin_state', $request->origin_state)
            ->where('destination_state', $request->destination_state)
            ->first();
            
        if (!$route) {
             return response()->json(['message' => 'Invalid Route'], 400);
        }

        $price = $route->base_price;
        if ($request->size === 'Medium') $price += $route->medium_surcharge;
        if ($request->size === 'Large') $price += $route->large_surcharge;
        
        // 2. Check Wallet Balance
        $wallet = $user->wallet()->firstOrCreate([], ['balance' => 0.00, 'currency' => 'NGN']);
        if ($wallet->balance < $price) {
            return response()->json(['message' => 'Insufficient wallet balance.'], 402);
        }

        // 3. Deduct Balance
        $wallet->balance -= $price;
        $wallet->save();
        
        // 4. Create Delivery Record
        $trackingNumber = 'GIGA-' . strtoupper(Str::random(10));
        
        $delivery = Delivery::create([
            'customer_id' => $user->id,
            'tracking_number' => $trackingNumber,
            'status' => 'pending_dropoff',
            'pickup_address' => $originLocker->name . ' (' . $request->origin_state . ')',
            'dropoff_address' => $destLocker->name . ' (' . $request->destination_state . ')',
            'parcel_size' => $request->size,
            'parcel_type' => 'Inter-State Waybill',
            'description' => $request->items_description,
            'fare' => $price,
            'estimated_duration' => $route->delivery_days . ' days',
            'recipient_name' => $request->recipient_name,
            'recipient_phone' => $request->recipient_phone,
            'pickup_lat' => $originLocker->latitude,
            'pickup_lng' => $originLocker->longitude,
            'dropoff_lat' => $destLocker->latitude,
            'dropoff_lng' => $destLocker->longitude,
        ]);

        return response()->json([
            'message' => 'Waybill generated successfully.',
            'waybill_number' => $trackingNumber,
            'dropoff_code' => rand(1000, 9999), 
            'delivery' => $delivery
        ], 201);
    }
}
