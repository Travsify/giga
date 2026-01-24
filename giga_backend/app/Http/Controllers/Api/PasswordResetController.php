<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Auth\Events\PasswordReset;

class PasswordResetController extends Controller
{
    /**
     * Send a password reset link to the given user.
     */
    public function sendResetLink(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Always return success to prevent email enumeration
        $user = User::where('email', $request->email)->first();
        
        if ($user) {
            // Generate a simple reset token (in production, use Password::sendResetLink with mail)
            $token = Str::random(64);
            
            // Store the token (you would typically use password_resets table)
            \DB::table('password_reset_tokens')->updateOrInsert(
                ['email' => $request->email],
                [
                    'token' => Hash::make($token),
                    'created_at' => now(),
                ]
            );
            
            // In production: Send email with reset link
            // Mail::to($user->email)->send(new PasswordResetMail($token));
            
            // For development: Return the token (remove in production!)
            return response()->json([
                'message' => 'If an account exists with this email, a reset link has been sent.',
                'dev_token' => $token, // REMOVE IN PRODUCTION
            ]);
        }

        return response()->json([
            'message' => 'If an account exists with this email, a reset link has been sent.',
        ]);
    }

    /**
     * Reset the given user's password.
     */
    public function reset(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'token' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Find the reset record
        $record = \DB::table('password_reset_tokens')
            ->where('email', $request->email)
            ->first();

        if (!$record) {
            return response()->json(['message' => 'Invalid reset token.'], 400);
        }

        // Check if token is valid
        if (!Hash::check($request->token, $record->token)) {
            return response()->json(['message' => 'Invalid reset token.'], 400);
        }

        // Check if token is expired (1 hour)
        if (now()->diffInMinutes($record->created_at) > 60) {
            return response()->json(['message' => 'Reset token has expired.'], 400);
        }

        // Update the user's password
        $user = User::where('email', $request->email)->first();
        
        if (!$user) {
            return response()->json(['message' => 'User not found.'], 404);
        }

        $user->password = Hash::make($request->password);
        $user->save();

        // Delete the reset token
        \DB::table('password_reset_tokens')->where('email', $request->email)->delete();

        // Revoke all tokens for security
        $user->tokens()->delete();

        return response()->json([
            'message' => 'Password has been reset successfully. Please login with your new password.',
        ]);
    }
}
