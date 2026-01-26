<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CurrencyRate;
use Illuminate\Http\Request;

class CurrencyController extends Controller
{
    /**
     * Get all active currency rates.
     */
    public function getRates()
    {
        $rates = CurrencyRate::where('is_active', true)
            ->get(['currency_code', 'symbol', 'rate_to_gbp', 'is_base']);

        return response()->json([
            'success' => true,
            'data' => $rates,
        ]);
    }
}
