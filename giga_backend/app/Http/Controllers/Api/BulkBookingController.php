<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Delivery;
use App\Models\Wallet;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class BulkBookingController extends Controller
{
    public function processBatch(Request $request)
    {
        $user = $request->user();
        $request->validate([
            'deliveries' => 'required|array|min:1|max:10',
            'deliveries.*.pickup_address' => 'required|string',
            'deliveries.*.delivery_address' => 'required|string',
            'deliveries.*.package_type' => 'required|string',
            'deliveries.*.weight' => 'required|numeric',
            'deliveries.*.estimated_fare' => 'required|numeric',
        ]);

        $batch = [];
        $totalFare = 0;

        foreach ($request->deliveries as $data) {
            $totalFare += $data['estimated_fare'];
        }

        // Check credit/balance
        $business = $user->logisticsCompany;
        if ($business) {
            $availableCredit = $business->credit_limit - $business->outstanding_balance;
            if ($availableCredit < $totalFare) {
                return response()->json(['message' => 'Insufficient credit limit for this batch.'], 402);
            }
        } else {
            $wallet = $user->wallet;
            if (!$wallet || $wallet->balance < $totalFare) {
                return response()->json(['message' => 'Insufficient wallet balance for this batch.'], 402);
            }
        }

        DB::beginTransaction();
        try {
            foreach ($request->deliveries as $data) {
                $delivery = Delivery::create([
                    'customer_id' => $user->id,
                    'pickup_address' => $data['pickup_address'],
                    'delivery_address' => $data['delivery_address'],
                    'package_type' => $data['package_type'],
                    'weight' => $data['weight'],
                    'estimated_fare' => $data['estimated_fare'],
                    'status' => 'pending',
                ]);
                $batch[] = $delivery;
            }

            // Deduct from business or wallet
            if ($business) {
                $business->increment('outstanding_balance', $totalFare);
            } else {
                $user->wallet->decrement('balance', $totalFare);
            }

            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Bulk Booking Error: ' . $e->getMessage());
            return response()->json(['message' => 'Failed to process bulk booking.'], 500);
        }

        return response()->json([
            'message' => 'Bulk booking processed successfully.',
            'deliveries' => $batch,
            'total_fare' => $totalFare
        ], 201);
    }
}
