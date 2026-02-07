<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;

class EmailVerificationController extends Controller
{
    /**
     * Send verification code to user's email
     */
    public function sendVerificationCode(Request $request)
    {
        $user = $request->user();

        // REMOVED: if ($user->email_verified_at) check to allow Login OTP (2FA)
        // if ($user->email_verified_at) {
        //    return response()->json(['message' => 'Email already verified.'], 400);
        // }

        // Generate 7-digit verification code
        $code = str_pad(random_int(0, 9999999), 7, '0', STR_PAD_LEFT);
        
        // Store the code with expiry (2 minutes)
        DB::table('email_verification_codes')->updateOrInsert(
            ['user_id' => $user->id],
            [
                'code' => $code,
                'expires_at' => now()->addMinutes(2),
                'created_at' => now(),
            ]
        );

        // Send email via ResendService (direct HTTP API)
        try {
            Log::info("Preparing to send OTP to {$user->email} using ResendService.");
            
            $resendService = app(\App\Services\ResendService::class);
            $html = "<h3>Verify Your Email</h3><p>Hello {$user->name},</p><p>Your verification code is: <strong>{$code}</strong></p><p>This code will expire in 2 minutes.</p>";
            
            $sent = $resendService->sendEmail($user->email, 'Verify Your Email - GIGA LOGISTICS', $html);
            
            if ($sent) {
                Log::info("OTP email successfully sent via ResendService to: {$user->email}");
                return response()->json([
                    'status' => 'success',
                    'message' => 'Verification code sent to your email.'
                ]);
            } else {
                $error = $resendService->getLastError();
                Log::error("Failed to send OTP email via ResendService to {$user->email}. Error: {$error}");
                return response()->json([
                    'message' => 'Failed to send verification code.',
                    'debug_error' => $error,
                ], 500);
            }
        } catch (\Exception $e) {
            Log::error("CRITICAL: Exception sending OTP email to {$user->email}. Error: " . $e->getMessage());
            
            return response()->json([
                'message' => 'Failed to send verification code. Server Error: ' . $e->getMessage(),
                'debug_error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Verify the code entered by user
     */
    public function verifyCode(Request $request)
    {
        $request->validate([
            'code' => 'required|string|size:7',
        ]);

        $user = $request->user();

        // REMOVED: if ($user->email_verified_at) check to allow Login OTP (2FA)
        // if ($user->email_verified_at) {
        //    return response()->json(['message' => 'Email already verified.'], 400);
        // }

        // Find the verification record
        $record = DB::table('email_verification_codes')
            ->where('user_id', $user->id)
            ->first();

        if (!$record) {
            return response()->json(['message' => 'No verification code found. Please request a new one.'], 400);
        }

        if ($record->code !== $request->code) {
            return response()->json(['message' => 'Invalid verification code.'], 400);
        }

        if (now()->gt($record->expires_at)) {
            return response()->json(['message' => 'Verification code has expired. Please request a new one.'], 400);
        }

        // Mark email as verified
        $user->email_verified_at = now();
        $user->save();

        // Delete the verification record
        DB::table('email_verification_codes')->where('user_id', $user->id)->delete();

        return response()->json([
            'message' => 'Email verified successfully!',
            'user' => $user,
        ]);
    }

    /**
     * Resend verification code
     */
    public function resendCode(Request $request)
    {
        return $this->sendVerificationCode($request);
    }

    /**
     * Public methods for Signup Verification
     */
    public function sendSignupCode(Request $request)
    {
        $request->validate(['email' => 'required|email']);
        $email = $request->email;

        // Check if email already exists
        if (\App\Models\User::where('email', $email)->exists()) {
            return response()->json(['message' => 'Email already registered.'], 400);
        }

        $code = str_pad(random_int(0, 9999999), 7, '0', STR_PAD_LEFT);
        
        DB::table('email_verification_codes')->updateOrInsert(
            ['email' => $email],
            [
                'code' => $code,
                'expires_at' => now()->addMinutes(2),
                'created_at' => now(),
            ]
        );

        // Send email via ResendService (direct HTTP API)
        try {
            Log::info("Preparing to send Signup OTP to {$email} using ResendService.");

            $resendService = app(\App\Services\ResendService::class);
            $html = "<h3>Welcome to Giga!</h3><p>Your signup verification code is: <strong>{$code}</strong></p><p>This code will expire in 2 minutes.</p>";
            
            $sent = $resendService->sendEmail($email, 'Verify Your Email - GIGA LOGISTICS', $html);
            
            if ($sent) {
                Log::info("Signup OTP email successfully sent via ResendService to: {$email}");
                return response()->json(['message' => 'Verification code sent.']);
            } else {
                $error = $resendService->getLastError();
                Log::error("Failed to send signup OTP email via ResendService to {$email}. Error: {$error}");
                return response()->json([
                    'message' => 'Failed to send verification code.',
                    'debug_error' => $error,
                ], 500);
            }
        } catch (\Exception $e) {
            Log::error("CRITICAL: Failed to send signup OTP email to {$email}. Error: " . $e->getMessage());
            
            return response()->json([
                'message' => 'Failed to send verification code. Server Error: ' . $e->getMessage(),
                'debug_error' => $e->getMessage(),
            ], 500);
        }
    }

    public function verifySignupCode(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'code' => 'required|string|size:7',
        ]);

        $record = DB::table('email_verification_codes')
            ->where('email', $request->email)
            ->first();

        if (!$record || $record->code !== $request->code || now()->gt($record->expires_at)) {
            return response()->json(['message' => 'Invalid or expired code.'], 400);
        }

        return response()->json(['message' => 'Email verified!']);
    }
}
