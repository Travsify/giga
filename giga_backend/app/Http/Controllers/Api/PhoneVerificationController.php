<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\AppSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Services\SmsService;

class PhoneVerificationController extends Controller
{
    protected $smsService;

    public function __construct(SmsService $smsService)
    {
        $this->smsService = $smsService;
    }

    /**
     * Send OTP to phone
     */
    public function sendOtp(Request $request)
    {
        Log::info("sendOtp called for phone: " . $request->phone);
        $request->validate(['phone' => 'required|string']);
        $phone = $request->phone;

        // Generate 6-digit verification code
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        
        // Store the code with expiry (2 minutes)
        DB::table('phone_verification_codes')->updateOrInsert(
            ['phone' => $phone],
            [
                'code' => $code,
                'expires_at' => now()->addMinutes(2),
                'created_at' => now(),
            ]
        );

        // Send SMS
        $sent = $this->smsService->send($phone, "Your Giga verification code is: {$code}");

        if (!$sent) {
            return response()->json(['message' => 'Failed to send SMS. Please try again or check logs.'], 500);
        }

        $responseData = ['message' => 'OTP sent successfully.'];
        if (AppSetting::get('sms_provider') === 'log' || config('app.debug')) {
            $responseData['debug_code'] = $code;
        }

        return response()->json($responseData);
    }

    /**
     * Verify the OTP
     */
    public function verifyOtp(Request $request)
    {
        $request->validate([
            'phone' => 'required|string',
            'code' => 'required|string|size:6',
        ]);

        $record = DB::table('phone_verification_codes')
            ->where('phone', $request->phone)
            ->first();

        if (!$record) {
            return response()->json(['message' => 'No verification code found. Request a new one.'], 400);
        }

        // Check if code matches
        if ($record->code !== $request->code) {
            return response()->json(['message' => 'Invalid verification code.'], 400);
        }

        // Check if expired
        if (now()->gt($record->expires_at)) {
            return response()->json(['message' => 'Verification code has expired. Request a new one.'], 400);
        }
        
        // If user is logged in, mark phone as verified
        if ($user = $request->user()) {
            // (Assuming user model has phone_verified_at, if not we just return success for signup flow)
            // $user->phone_verified_at = now();
            // $user->save();
        }

        // Delete the verification record
        // DB::table('phone_verification_codes')->where('phone', $request->phone)->delete();

        return response()->json(['message' => 'Phone verified successfully!']);
    }
}
