<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Promo;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class PromoController extends Controller
{
    public function index()
    {
        $promos = Promo::where('is_active', true)
            ->where(function($query) {
                $query->whereNull('expires_at')
                      ->orWhere('expires_at', '>', now());
            })
            ->get();

        return response()->json($promos);
    }

    public function validateCode(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'code' => 'required|string',
            'order_amount' => 'required|numeric'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $code = strtoupper($request->code);
        $promo = Promo::where('code', $code)
            ->where('is_active', true)
            ->where(function($query) {
                $query->whereNull('expires_at')
                      ->orWhere('expires_at', '>', now());
            })
            ->first();

        if (!$promo) {
            return response()->json(['message' => 'Invalid or expired promo code'], 404);
        }

        if ($request->order_amount < $promo->min_order_amount) {
            return response()->json([
                'message' => "Minimum order amount of £{$promo->min_order_amount} required"
            ], 422);
        }

        if ($promo->max_uses && $promo->used_count >= $promo->max_uses) {
            return response()->json(['message' => 'This promo code has reached its usage limit'], 422);
        }

        $discountValue = 0;
        if ($promo->discount_type === 'fixed') {
            $discountValue = $promo->discount_value;
        } else {
            $discountValue = ($promo->discount_value / 100) * $request->order_amount;
            if ($promo->max_discount_amount) {
                $discountValue = min($discountValue, $promo->max_discount_amount);
            }
        }

        return response()->json([
            'promo' => $promo,
            'discount_amount' => round($discountValue, 2),
            'final_amount' => round(max(0, $request->order_amount - $discountValue), 2)
        ]);
    }
}
