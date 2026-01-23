<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class SubscriptionController extends Controller
{
    /**
     * Get current subscription status.
     */
    public function status()
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();
        
        return response()->json([
            'is_giga_plus' => (bool) $user->is_giga_plus,
            'expiry' => $user->giga_plus_expiry ? $user->giga_plus_expiry->toDateTimeString() : null,
            'days_left' => $user->giga_plus_expiry ? Carbon::now()->diffInDays($user->giga_plus_expiry, false) : 0,
        ]);
    }

    /**
     * Subscribe to Giga+ (Mock payment integration).
     */
    public function subscribe(Request $request)
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        // Standard Giga+ subscription is 30 days for £9.99 (Simulated)
        $user->is_giga_plus = true;
        
        // If already active, extend; else start from now
        $baseDate = ($user->giga_plus_expiry && $user->giga_plus_expiry->isFuture()) 
            ? $user->giga_plus_expiry 
            : Carbon::now();
            
        $user->giga_plus_expiry = $baseDate->addDays(30);
        $user->save();

        return response()->json([
            'message' => 'Welcome to Giga+! Your subscription is active.',
            'is_giga_plus' => true,
            'expiry' => $user->giga_plus_expiry->toDateTimeString(),
        ]);
    }

    /**
     * Cancel / Resume (Logic placeholder for real subscriptions)
     */
    public function cancel()
    {
        // For a mock, we'll just let it expire.
        return response()->json(['message' => 'Auto-renewal disabled (Simulated).']);
    }
}
