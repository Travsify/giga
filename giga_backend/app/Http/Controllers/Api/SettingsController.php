<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use Illuminate\Http\JsonResponse;

class SettingsController extends Controller
{
    /**
     * Get all public app settings for mobile app
     */
    public function index(): JsonResponse
    {
        $settings = AppSetting::getPublicSettings();

        // Add computed fields
        $settings['api_version'] = '1.0';
        $settings['server_time'] = now()->toIso8601String();

        return response()->json([
            'success' => true,
            'data' => $settings,
        ]);
    }

    /**
     * Check if app update is required
     */
    public function checkVersion(string $version): JsonResponse
    {
        $minVersion = AppSetting::get('min_app_version', '1.0.0');
        $currentVersion = AppSetting::get('app_version', '1.0.0');
        $maintenanceMode = AppSetting::get('maintenance_mode', false);

        $updateRequired = version_compare($version, $minVersion, '<');
        $updateAvailable = version_compare($version, $currentVersion, '<');

        return response()->json([
            'success' => true,
            'data' => [
                'current_version' => $currentVersion,
                'min_version' => $minVersion,
                'update_required' => $updateRequired,
                'update_available' => $updateAvailable,
                'maintenance_mode' => $maintenanceMode,
                'maintenance_message' => $maintenanceMode ? AppSetting::get('maintenance_message', '') : null,
            ],
        ]);
    }
}
