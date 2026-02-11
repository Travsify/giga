<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LogisticsCompany;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use App\Models\ApiKey;

class BusinessController extends Controller
{
    public function enroll(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'company_type' => 'required|in:LTD,PLC,Sole Trader',
            'registration_number' => 'required|string|unique:logistics_companies,registration_number',
            'vat_number' => 'nullable|string',
            'business_email' => 'required|email|unique:logistics_companies,business_email',
            'address' => 'required|string',
            'contact_phone' => 'required|string',
            'website' => 'nullable|url',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Create the business profile
        $business = LogisticsCompany::create([
            'user_id' => $user->id,
            'name' => $request->name,
            'company_type' => $request->company_type,
            'business_email' => $request->business_email,
            'registration_number' => $request->registration_number,
            'vat_number' => $request->vat_number,
            'address' => $request->address,
            'website' => $request->website,
            'contact_phone' => $request->contact_phone,
            'is_verified' => false, // Requires manual verification by Giga Admin
            'credit_limit' => 500.00, // Starting credit for new businesses
        ]);

        // Update user role
        $user->update(['role' => 'Business']);

        return response()->json([
            'message' => 'Business enrollment submitted successfully. Your profile is pending verification.',
            'business' => $business
        ], 201);
    }

    public function getProfile(Request $request)
    {
        $business = $request->user()->logisticsCompany;
        if (!$business) {
            return response()->json(['message' => 'No business profile found.'], 404);
        }
        return response()->json($business);
    }

    public function getTeam(Request $request)
    {
        $business = $request->user()->logisticsCompany;
        if (!$business) {
            return response()->json(['message' => 'Not a business account.'], 403);
        }

        $members = $business->members()->get();
        $invitations = $business->invitations()->where('expires_at', '>', now())->get();

        return response()->json([
            'members' => $members,
            'invitations' => $invitations,
        ]);
    }

    public function inviteMember(Request $request)
    {
        $business = $request->user()->logisticsCompany;
        if (!$business) {
            return response()->json(['message' => 'Not a business account.'], 403);
        }

        $request->validate([
            'email' => 'required|email',
            'role' => 'required|in:Admin,Member',
        ]);

        $invitation = \App\Models\BusinessInvitation::updateOrCreate(
            ['business_id' => $business->id, 'email' => $request->email],
            [
                'role' => $request->role,
                'token' => \Illuminate\Support\Str::random(32),
                'expires_at' => now()->addDays(7),
            ]
        );

        // In a real app, send invitation email here
        
        return response()->json([
            'message' => 'Invitation sent successfully.',
            'invitation' => $invitation
        ]);
    }

    public function getBilling(Request $request)
    {
        $business = $request->user()->logisticsCompany;
        if (!$business) {
            return response()->json(['message' => 'Not a business account.'], 403);
        }

        return response()->json([
            'credit_limit' => $business->credit_limit,
            'outstanding_balance' => $business->outstanding_balance,
            'invoices' => [
                ['id' => 1, 'amount' => 120.50, 'status' => 'Paid', 'date' => '2026-01-10'],
                ['id' => 2, 'amount' => 450.00, 'status' => 'Pending', 'date' => '2026-01-20'],
            ]
        ]);
    }

    public function getFleetRiders(Request $request)
    {
        $business = $request->user()->logisticsCompany;
        if (!$business) {
            return response()->json(['message' => 'Not a business account.'], 403);
        }

        $riders = $business->riders()->with('user')->get();

        return response()->json([
            'status' => 'success',
            'data' => $riders
        ]);
    }

    public function onboardRider(Request $request)
    {
        $business = $request->user()->logisticsCompany;
        if (!$business) {
            return response()->json(['message' => 'Not a business account.'], 403);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'phone' => 'nullable|string',
            'password' => 'required|string|min:8',
            'license_number' => 'required|string|unique:riders,license_number',
            'vehicle_type' => 'required|string',
            'vehicle_plate_number' => 'required|string|unique:riders,vehicle_plate_number',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        return DB::transaction(function () use ($request, $business) {
            // Create the user
            $user = \App\Models\User::create([
                'name' => $request->name,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'role' => 'Rider',
                'uk_phone' => $request->phone,
                'email_verified_at' => now(), // Auto-verify fleet-onboarded riders
                'country_code' => $business->user->country_code,
                'currency_code' => $business->user->currency_code,
            ]);

            // Create the rider profile linked to the company
            $rider = \App\Models\Rider::create([
                'user_id' => $user->id,
                'logistics_company_id' => $business->id,
                'license_number' => $request->license_number,
                'vehicle_type' => $request->vehicle_type,
                'vehicle_plate_number' => $request->vehicle_plate_number,
                'verification_status' => 'verified', // Fleet riders are verified by their company
                'is_online' => false,
                'has_vehicle' => true,
                'vehicle_verified' => true,
            ]);

            // Create wallet
            \App\Models\Wallet::create([
                'user_id' => $user->id,
                'balance' => 0.00,
                'currency' => $user->currency_code,
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Rider onboarded successfully to your fleet.',
                'rider' => $rider->load('user')
            ], 201);
        });
    }

    public function getStats(Request $request)
    {
        $business = $request->user()->logisticsCompany;
        if (!$business) {
            return response()->json(['message' => 'Not a business account.'], 403);
        }

        // Aggregate stats for the fleet
        $riderIds = $business->riders()->pluck('id');
        
        $totalEarnings = \App\Models\Transaction::whereIn('user_id', function($query) use ($business) {
            $query->select('user_id')->from('riders')->where('logistics_company_id', $business->id);
        })->where('type', 'credit')->sum('amount');

        $activeDeliveries = \App\Models\Delivery::whereIn('rider_id', $riderIds)
            ->whereIn('status', ['accepted', 'picked_up'])
            ->count();

        return response()->json([
            'total_riders' => $riderIds->count(),
            'online_riders' => $business->riders()->where('is_online', true)->count(),
            'total_fleet_earnings' => (float)$totalEarnings,
            'active_deliveries' => $activeDeliveries,
            'credit_limit' => $business->credit_limit,
            'outstanding_balance' => $business->outstanding_balance,
        ]);
    }

    public function getRecentActivity(Request $request)
    {
        $business = $request->user()->logisticsCompany;
        if (!$business) {
            return response()->json(['message' => 'Not a business account.'], 403);
        }

        $riderIds = $business->riders()->pluck('id');

        $deliveries = \App\Models\Delivery::whereIn('rider_id', $riderIds)
            ->orderBy('updated_at', 'desc')
            ->limit(10)
            ->get();

        return response()->json($deliveries);
    }

    /**
     * Generate a new API key for the business.
     */
    public function generateApiKey(Request $request)
    {
        $business = $request->user()->logisticsCompany;
        if (!$business) {
            return response()->json(['message' => 'Not a business account.'], 403);
        }

        if (!$business->is_verified) {
            return response()->json(['message' => 'Your business must be verified before generating API keys.'], 403);
        }

        $request->validate([
            'name' => 'required|string|max:100',
        ]);

        // Limit to 5 active keys per business
        $activeKeys = ApiKey::where('logistics_company_id', $business->id)
            ->where('is_active', true)
            ->count();

        if ($activeKeys >= 5) {
            return response()->json(['message' => 'Maximum 5 active API keys allowed. Revoke an existing key first.'], 422);
        }

        // Generate a secure random key
        $plainKey = 'giga_' . Str::random(48);
        $prefix = substr($plainKey, 0, 12); // Visible prefix for identification

        $apiKey = ApiKey::create([
            'logistics_company_id' => $business->id,
            'name' => $request->name,
            'key' => hash('sha256', $plainKey),
            'prefix' => $prefix,
            'is_active' => true,
        ]);

        return response()->json([
            'message' => 'API key generated successfully. Store this key securely — it will not be shown again.',
            'data' => [
                'id' => $apiKey->id,
                'name' => $apiKey->name,
                'key' => $plainKey, // Only shown once
                'prefix' => $prefix,
                'created_at' => $apiKey->created_at,
            ]
        ], 201);
    }

    /**
     * List all API keys for the business (keys are masked).
     */
    public function listApiKeys(Request $request)
    {
        $business = $request->user()->logisticsCompany;
        if (!$business) {
            return response()->json(['message' => 'Not a business account.'], 403);
        }

        $keys = ApiKey::where('logistics_company_id', $business->id)
            ->select('id', 'name', 'prefix', 'is_active', 'last_used_at', 'created_at')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $keys,
        ]);
    }

    /**
     * Revoke (deactivate) an API key.
     */
    public function revokeApiKey(Request $request, $keyId)
    {
        $business = $request->user()->logisticsCompany;
        if (!$business) {
            return response()->json(['message' => 'Not a business account.'], 403);
        }

        $apiKey = ApiKey::where('id', $keyId)
            ->where('logistics_company_id', $business->id)
            ->first();

        if (!$apiKey) {
            return response()->json(['message' => 'API key not found.'], 404);
        }

        if (!$apiKey->is_active) {
            return response()->json(['message' => 'API key is already revoked.'], 422);
        }

        $apiKey->update(['is_active' => false]);

        return response()->json([
            'message' => 'API key revoked successfully.',
            'data' => [
                'id' => $apiKey->id,
                'name' => $apiKey->name,
                'is_active' => false,
            ]
        ]);
    }
}
