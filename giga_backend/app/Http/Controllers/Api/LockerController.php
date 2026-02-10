<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Models\Locker;
use App\Models\Delivery;

class LockerController extends Controller
{
    public function index()
    {
        return response()->json(Locker::all());
    }

    public function show($id)
    {
        return response()->json(Locker::findOrFail($id));
    }

    /**
     * Initiate a locker-to-locker P2P shipment (UK).
     */
    public function initiateP2PShipment(Request $request): JsonResponse
    {
        $request->validate([
            'origin_locker_id' => 'required|exists:lockers,id',
            'destination_locker_id' => 'required|exists:lockers,id',
        ]);

        $delivery = Delivery::create([
            'customer_id' => $request->user()->id,
            'parcel_type' => 'Locker P2P',
            'description' => "Locker Shipment from {$request->origin_locker_id} to {$request->destination_locker_id}",
            'pickup_address' => "Locker #{$request->origin_locker_id}",
            'dropoff_address' => "Locker #{$request->destination_locker_id}",
            'locker_id' => $request->origin_locker_id,
            'status' => 'pending',
            'fare' => 3.50, // Flat UK locker rate
            'service_category' => 'locker_p2p'
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Locker shipment initiated. Drop off your parcel at the origin locker.',
            'data' => $delivery
        ]);
    }
}
