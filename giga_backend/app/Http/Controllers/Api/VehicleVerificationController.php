<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class VehicleVerificationController extends Controller
{
    /**
     * Verify vehicle details via Plate Number (VRN)
     */
    public function verify(Request $request)
    {
        $request->validate([
            'plate_number' => 'required|string',
            'country_code' => 'required|string|in:NG,UK',
        ]);

        $plateNumber = strtoupper(str_replace(' ', '', $request->plate_number));
        $countryCode = $request->country_code;

        try {
            if ($countryCode === 'NG') {
                return $this->verifyNigeria($plateNumber);
            } else {
                return $this->verifyUK($plateNumber);
            }
        } catch (\Exception $e) {
            Log::error('Vehicle Verification Error: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Verification failed: ' . $e->getMessage(),
                'debug' => env('APP_DEBUG') ? $e->getMessage() : null
            ], 503);
        }
    }

    /**
     * Verify Nigeria Plate Number via IdentityPass (Prembly)
     */
    private function verifyNigeria($plateNumber)
    {
        $apiKey = env('PREMBLY_API_KEY');
        if (!$apiKey || $apiKey === 'MOCK') {
            // Mock response for development if no key
            return response()->json([
                'status' => 'success',
                'source' => 'mock_identitypass',
                'data' => [
                    'make' => 'TOYOTA',
                    'model' => 'COROLLA',
                    'color' => 'SILVER',
                    'owner' => 'TEST USER',
                    'expiry' => '2025-12-31',
                    'plate' => $plateNumber,
                ]
            ]);
        }

        $response = Http::withHeaders([
            'x-api-key' => $apiKey,
        ])->post('https://api.prembly.com/identitypass/verification/frsc', [
            'number' => $plateNumber
        ]);

        if ($response->successful()) {
            $data = $response->json();
            return response()->json([
                'status' => 'success',
                'data' => [
                    'make' => $data['data']['make'] ?? 'Unknown',
                    'model' => $data['data']['model'] ?? 'Unknown',
                    'color' => $data['data']['color'] ?? 'Unknown',
                    'plate' => $plateNumber,
                ]
            ]);
        }

        return response()->json([
            'status' => 'error',
            'message' => 'Plate number not found or invalid format.'
        ], 404);
    }

    /**
     * Verify UK Plate Number via DVLA API
     */
    private function verifyUK($plateNumber)
    {
        $apiKey = env('DVLA_API_KEY');
        if (!$apiKey) {
            return response()->json([
                'status' => 'success',
                'source' => 'mock_dvla',
                'data' => [
                    'make' => 'HONDA',
                    'model' => 'CIVIC',
                    'color' => 'BLUE',
                    'year' => '2022'
                ]
            ]);
        }

        $response = Http::withHeaders([
            'x-api-key' => $apiKey,
        ])->post('https://driver-vehicle-licensing.api.gov.uk/vehicle-enquiry/v1/vehicles', [
            'registrationNumber' => $plateNumber
        ]);

        if ($response->successful()) {
            $data = $response->json();
            return response()->json([
                'status' => 'success',
                'data' => [
                    'make' => $data['make'] ?? 'Unknown',
                    'model' => $data['model'] ?? 'Unknown',
                    'color' => $data['colour'] ?? 'Unknown',
                    'year' => $data['yearOfManufacture'] ?? 'Unknown',
                ]
            ]);
        }

        return response()->json([
            'status' => 'error',
            'message' => 'UK Registration not found.'
        ], 404);
    }

    /**
     * Upload rider/vehicle documents
     */
    public function uploadDocument(Request $request)
    {
        $request->validate([
            'type' => 'required|string|in:vehicle_license,insurance,driver_license,vehicle_registration',
            'file' => 'required|file|mimes:jpg,jpeg,png,pdf|max:5120', // 5MB max
        ]);

        $user = $request->user();
        $rider = $user->rider;

        if (!$rider) {
            return response()->json(['status' => 'error', 'message' => 'Rider profile not found.'], 404);
        }

        $type = $request->type;
        $file = $request->file('file');
        
        $path = $file->store('rider_documents/' . $user->id, 'public');

        switch ($type) {
            case 'vehicle_license':
                $rider->vehicle_license_path = $path;
                break;
            case 'insurance':
                $rider->insurance_certificate_path = $path;
                break;
            case 'driver_license':
                $rider->driver_license_path = $path;
                break;
            case 'vehicle_registration':
                $rider->vehicle_registration_path = $path;
                break;
        }

        // Auto-update status to 'submitted' if certain key docs are in
        if ($rider->driver_license_path && $rider->vehicle_license_path) {
            $rider->verification_status = 'submitted';
        }

        $rider->save();

        return response()->json([
            'status' => 'success',
            'message' => str_replace('_', ' ', ucfirst($type)) . ' uploaded successfully.',
            'path' => $path,
            'verification_status' => $rider->verification_status
        ]);
    }
}
