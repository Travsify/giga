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

use App\Services\ResendService;

class EmailVerificationController extends Controller
{
    protected $resend;

    public function __construct(ResendService $resend)
    {
        $this->resend = $resend;
    }
    /**
     * Send verification code to user's email
     */
    public function sendVerificationCode(Request $request)
    {
        $user = $request->user();

        if ($user->email_verified_at) {
            return response()->json(['message' => 'Email already verified.'], 400);
        }

        // Generate 7-digit verification code
        $code = str_pad(random_int(0, 9999999), 7, '0', STR_PAD_LEFT);
        
        // Store the code with expiry (15 minutes)
        \DB::table('email_verification_codes')->updateOrInsert(
            ['user_id' => $user->id],
            [
                'code' => $code,
                'expires_at' => now()->addMinutes(2),
                'created_at' => now(),
            ]
        );

        // Send email via Resend
        $html = "<h3>Verify Your Email</h3><p>Hello {$user->name},</p><p>Your verification code is: <strong>{$code}</strong></p><p>This code will expire in 15 minutes.</p>";
        $sent = $this->resend->sendEmail($user->email, 'Verify Your Email - GIGA LOGISTICS', $html);

        if (!$sent) {
            \Log::error("Failed to send verification email to {$user->email}");
        }

        return response()->json([
            'message' => 'Verification code sent to your email.',
        ]);
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

        if ($user->email_verified_at) {
            return response()->json(['message' => 'Email already verified.'], 400);
        }

        // Find the verification record
        $record = \DB::table('email_verification_codes')
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
            return response()->json(['message' => 'Verification code has expired. Request a new one.'], 400);
        }

        // Mark email as verified
        $user->email_verified_at = now();
        $user->save();

        // Delete the verification record
        \DB::table('email_verification_codes')->where('user_id', $user->id)->delete();

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
        
        \DB::table('email_verification_codes')->updateOrInsert(
            ['email' => $email], // We'll need to use email instead of user_id for signup codes
            [
                'code' => $code,
                'expires_at' => now()->addMinutes(2),
                'created_at' => now(),
            ]
        );

        $html = "<h3>Welcome to Giga!</h3><p>Your signup verification code is: <strong>{$code}</strong></p>";
        $this->resend->sendEmail($email, 'Verify Your Email - GIGA LOGISTICS', $html);

        return response()->json(['message' => 'Verification code sent.']);
    }

    public function verifySignupCode(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'code' => 'required|string|size:7',
        ]);

        $record = \DB::table('email_verification_codes')
            ->where('email', $request->email)
            ->first();

        if (!$record || $record->code !== $request->code || now()->gt($record->expires_at)) {
            return response()->json(['message' => 'Invalid or expired code.'], 400);
        }

        // We don't delete yet, it will be used at registration time or just let it expire
        return response()->json(['message' => 'Email verified!']);
    }
}
