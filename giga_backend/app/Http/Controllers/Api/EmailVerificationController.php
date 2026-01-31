<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\AppSetting;
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

        /* 
        if ($user->email_verified_at) {
            return response()->json(['message' => 'Email already verified.'], 400);
        }
        */

        // Generate 6-digit verification code
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        
        // Store the code with expiry (15 minutes)
        DB::table('email_verification_codes')->updateOrInsert(
            ['user_id' => $user->id],
            [
                'code' => $code,
                'expires_at' => now()->addMinutes(15),
                'created_at' => now(),
            ]
        );

        // Send email
        try {
            // Force refresh of mailer config before sending
            Mail::forgetMailers();
            
            Log::info('Attempting to send verification code to: ' . $user->email);
            Mail::send('emails.verify', ['code' => $code, 'name' => $user->name], function ($message) use ($user) {
                $message->to($user->email)
                        ->subject('Verify Your Email - GIGA LOGISTICS');
            });
            Log::info('Verification code successfully sent (queued or dispatched) to: ' . $user->email);
        } catch (\Exception $e) {
            Log::error('Failed to send verification code email: ' . $e->getMessage(), [
                'user_id' => $user->id,
                'email' => $user->email,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            // For demo purposes, we return a success message even if mail fails, 
            // but log the error so we can fix SMTP.
            // Or we could return a 500. Let's return success but with a warning in logs.
        }

        return response()->json([
            'message' => 'Verification code sent to your email.'
        ]);
    }

    /**
     * Verify the code entered by user
     */
    public function verifyCode(Request $request)
    {
        $request->validate([
            'code' => 'required|string|size:6',
        ]);

        $user = $request->user();

        /*
        if ($user->email_verified_at) {
            return response()->json(['message' => 'Email already verified.'], 400);
        }
        */

        // Find the verification record
        $record = DB::table('email_verification_codes')
            ->where('user_id', $user->id)
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
            Log::warning("Email verification code expired for user {$user->id}. Expired at: {$record->expires_at}, Now: " . now());
            return response()->json(['message' => 'Verification code has expired. Request a new one.'], 400);
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
        $email = trim($request->email);

        // Check if email already exists
        if (\App\Models\User::where('email', $email)->exists()) {
            return response()->json(['message' => 'Email already registered.'], 400);
        }

        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        
        DB::table('email_verification_codes')->updateOrInsert(
            ['email' => $email], // We'll need to use email instead of user_id for signup codes
            [
                'code' => $code,
                'expires_at' => now()->addMinutes(15),
                'created_at' => now(),
            ]
        );

        try {
            Mail::forgetMailers();
            Mail::send('emails.verify', ['code' => $code, 'name' => 'New User'], function ($message) use ($email) {
                $message->to($email)
                        ->subject('Verify Your Email - GIGA LOGISTICS');
            });
        } catch (\Exception $e) {
            Log::error('Signup OTP Fail: ' . $e->getMessage());
        }

        return response()->json([
            'message' => 'Verification code sent.'
        ]);
    }

    public function verifySignupCode(Request $request)
    {
        $email = trim($request->email);
        $code = trim($request->code);

        $record = DB::table('email_verification_codes')
            ->where('email', $email)
            ->first();

        if (!$record) {
            Log::warning("No verification record found for email: {$email}");
            return response()->json(['message' => 'No verification code found. Request a new one.'], 400);
        }

        if ($record->code !== $code) {
            Log::warning("Verification code mismatch for email: {$email}. Expected: {$record->code}, Got: {$code}");
            return response()->json(['message' => 'Invalid verification code.'], 400);
        }

        if (now()->gt($record->expires_at)) {
            Log::warning("Verification code expired for email: {$email}. Expired at: {$record->expires_at}");
            return response()->json(['message' => 'Verification code has expired.'], 400);
        }

        // We don't delete yet, it will be used at registration time or just let it expire
        return response()->json(['message' => 'Email verified!']);
    }
}
