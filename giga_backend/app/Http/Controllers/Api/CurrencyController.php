<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Models\AppSetting;

class CurrencyController extends Controller
{
    /**
     * Get real-time exchange rates
     */
    public function getRates(Request $request): JsonResponse
    {
        // In production, this would call an external API like Fixer.io or ExchangeRate-API
        // For now, we fetch from AppSettings which acts as our caching layer
        $ngnRate = AppSetting::get('ngn_exchange_rate', 2000.00);
        $lastUpdate = now()->toIso8601String();

        return response()->json([
            'success' => true,
            'data' => [
                'base' => 'GBP',
                'rates' => [
                    'NGN' => (float)$ngnRate,
                    'USD' => 1.27,
                    'EUR' => 1.17,
                ],
                'last_updated' => $lastUpdate
            ]
        ]);
    }
}
