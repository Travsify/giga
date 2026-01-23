<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use Illuminate\Support\Str;

class ProfileController extends Controller
{
    /**
     * Get the authenticated user's profile.
     */
    public function show()
    {
        $user = Auth::user();
        
        // Generate referral code if not exists
        if (!$user->referral_code) {
            $user->referral_code = strtoupper(Str::random(8));
            $user->save();
        }

        return response()->json($user);
    }

    /**
     * Update the authenticated user's profile.
     */
    public function update(Request $request)
    {
        $user = Auth::user();

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'uk_phone' => 'sometimes|string|max:20',
            'home_address' => 'sometimes|string|max:255',
            'work_address' => 'sometimes|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user->update($request->only(['name', 'uk_phone', 'home_address', 'work_address']));

        return response()->json($user);
    }

    /**
     * Get loyalty and referral info.
     */
    public function loyaltyInfo()
    {
        $user = Auth::user();

        return response()->json([
            'loyalty_points' => $user->loyalty_points,
            'referral_code' => $user->referral_code,
            'referral_count' => $user->referrals()->count(),
            'referral_earnings' => $user->referrals()->count() * 10, // £10 per referral
        ]);
    }

    /**
     * Submit a referral code.
     */
    public function submitReferral(Request $request)
    {
        $user = Auth::user();

        if ($user->referred_by_id) {
            return response()->json(['error' => 'You have already been referred.'], 400);
        }

        $validator = Validator::make($request->all(), [
            'code' => 'required|string|exists:users,referral_code',
        ]);

        if ($validator->fails()) {
            return response()->json(['error' => 'Invalid referral code.'], 422);
        }

        $referrer = User::where('referral_code', $request->code)->first();

        if ($referrer->id === $user->id) {
            return response()->json(['error' => 'You cannot refer yourself.'], 400);
        }

        $user->referred_by_id = $referrer->id;
        $user->loyalty_points += 10; // New user gets £10 credit
        $user->save();

        $referrer->loyalty_points += 10; // Referrer gets £10 credit
        $referrer->save();

        return response()->json(['message' => 'Referral code applied. £10 credit added to both of you!']);
    }
}
