<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LogisticsCompany;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

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

    public function getStats(Request $request)
    {
        $user = $request->user();
        $business = $user->logisticsCompany ?? $user->business;

        if (!$business) {
            return response()->json(['message' => 'Not a business account.'], 403);
        }

        $memberCount = $business->members()->count();
        $activeDeliveries = \App\Models\Delivery::whereHas('customer', function($q) use ($business) {
            $q->where('business_id', $business->id);
        })->whereIn('status', ['pending', 'assigned', 'picked_up', 'in_transit'])->count();

        return response()->json([
            'member_count' => $memberCount,
            'active_deliveries' => $activeDeliveries,
            'credit_limit' => (float) $business->credit_limit,
            'outstanding_balance' => (float) $business->outstanding_balance,
            'currency' => $user->currency_code ?? 'GBP',
        ]);
    }

    public function getRecentActivity(Request $request)
    {
        $user = $request->user();
        $business = $user->logisticsCompany ?? $user->business;

        if (!$business) {
            return response()->json(['message' => 'Not a business account.'], 403);
        }

        // Combine recent shipments and recent invitations
        $deliveries = \App\Models\Delivery::whereHas('customer', function($q) use ($business) {
            $q->where('business_id', $business->id);
        })->orderBy('created_at', 'desc')->limit(5)->get()->map(function($d) {
            return [
                'type' => 'delivery',
                'title' => 'Bulk Order Created',
                'subtitle' => $d->parcel_type . ' to ' . $d->dropoff_address,
                'time' => $d->created_at->diffForHumans(),
                'status' => $d->status,
            ];
        });

        $invites = $business->invitations()->orderBy('created_at', 'desc')->limit(3)->get()->map(function($i) {
            return [
                'type' => 'invite',
                'title' => 'Member Invited',
                'subtitle' => $i->email,
                'time' => $i->created_at->diffForHumans(),
                'status' => 'pending',
            ];
        });

        $activity = $deliveries->concat($invites)->sortByDesc('time')->values();

        return response()->json($activity);
    }
}
