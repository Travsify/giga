<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Models\User;

class NotificationController extends Controller
{
    /**
     * Get user notification history
     */
    public function getNotifications(Request $request): JsonResponse
    {
        $user = $request->user();
        
        // Mock data for notifications
        return response()->json([
            'success' => true,
            'data' => [
                [
                    'id' => 1,
                    'title' => 'Ride Assigned',
                    'body' => 'Rider John (ID: 442) has been assigned to your delivery.',
                    'type' => 'delivery_update',
                    'read' => true,
                    'created_at' => now()->subHours(1)->toIso8601String(),
                ],
                [
                    'id' => 2,
                    'title' => 'Wallet Funded',
                    'body' => 'Your wallet has been credited with £50.00.',
                    'type' => 'payment',
                    'read' => false,
                    'created_at' => now()->subHours(5)->toIso8601String(),
                ]
            ]
        ]);
    }

    /**
     * Update notification settings/token
     */
    public function updateToken(Request $request): JsonResponse
    {
        $request->validate([
            'fcm_token' => 'required|string',
            'device_type' => 'nullable|string|in:ios,android',
        ]);

        $user = $request->user();
        // logic to save token for push notifications
        
        return response()->json([
            'success' => true,
            'message' => 'Notification token updated successfully'
        ]);
    }
}
