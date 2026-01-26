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

        // Convert storage paths to full URLs
        $imageFields = ['logo_url', 'icon_url', 'splash_image', 'onboarding_image_1', 'onboarding_image_2', 'onboarding_image_3'];
        foreach ($imageFields as $field) {
            if (!empty($settings[$field]) && !filter_var($settings[$field], FILTER_VALIDATE_URL)) {
                $settings[$field] = url('storage/' . $settings[$field]);
            }
        }

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
    /**
     * Get list of active countries
     */
    public function getCountries(): JsonResponse
    {
        $countries = \App\Models\Country::where('is_active', true)->get();
        return response()->json([
            'success' => true,
            'data' => $countries
        ]);
    }

    /**
     * Get list of active currency rates
     */
    public function getCurrencyRates(): JsonResponse
    {
        // Cache for performance if needed, but for now direct DB
        $rates = \App\Models\CurrencyRate::where('is_active', true)->get();
        return response()->json([
            'success' => true,
            'data' => $rates
        ]);
    }
}
