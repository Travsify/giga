<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ReturnRequest;
use App\Models\Delivery;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReturnRequestController extends Controller
{
    /**
     * Create a new retail return request.
     */
    public function create(Request $request): JsonResponse
    {
        $request->validate([
            'retailer_name' => 'required|string',
            'order_number' => 'nullable|string',
            'return_method' => 'required|in:no_label,qr_code,pre_printed',
            'pickup_address' => 'required|string',
            'pickup_lat' => 'required|numeric',
            'pickup_lng' => 'required|numeric',
        ]);

        return DB::transaction(function() use ($request) {
            // Create a specialized delivery for the return
            $delivery = Delivery::create([
                'customer_id' => $request->user()->id,
                'parcel_type' => 'Retail Return',
                'description' => "Return for {$request->retailer_name} (Order: {$request->order_number})",
                'pickup_address' => $request->pickup_address,
                'pickup_lat' => $request->pickup_lat,
                'pickup_lng' => $request->pickup_lng,
                'dropoff_address' => "Giga Hub Office ({$request->retailer_name} Sorting)",
                'dropoff_lat' => 51.5283, // Mock London Hub
                'dropoff_lng' => -0.0655,
                'vehicle_type' => 'Bike',
                'service_tier' => 'Standard',
                'fare' => 4.99, // Flat return fee for UK
                'status' => 'pending',
                'service_category' => 'return'
            ]);

            $returnRequest = ReturnRequest::create([
                'user_id' => $request->user()->id,
                'retailer_name' => $request->retailer_name,
                'order_number' => $request->order_number,
                'return_method' => $request->return_method,
                'status' => 'pending',
                'delivery_id' => $delivery->id
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Return request created. A rider will pick it up shortly.',
                'data' => $returnRequest->load('delivery')
            ]);
        });
    }

    /**
     * Get user's return history.
     */
    public function index(Request $request): JsonResponse
    {
        $returns = ReturnRequest::where('user_id', $request->user()->id)
            ->with('delivery')
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $returns
        ]);
    }
}
