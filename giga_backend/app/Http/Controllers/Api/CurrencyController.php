<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Currency;
use Illuminate\Http\Request;

class CurrencyController extends Controller
{
    public function index()
    {
        // Return all active currencies
        $currencies = Currency::where('is_active', true)->get();
        return response()->json($currencies);
    }
}
