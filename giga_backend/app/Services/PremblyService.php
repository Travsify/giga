<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class PremblyService
{
    protected string $apiKey;
    protected string $baseUrl;
    protected ?string $lastError = null;

    public function __construct()
    {
        $this->apiKey = config('services.prembly.key', env('PREMBLY_API_KEY', ''));
        $this->baseUrl = config('services.prembly.base_url', 'https://api.prembly.com');
    }

    public function getLastError(): ?string
    {
        return $this->lastError;
    }

    /**
     * Verify Nigerian Driver's License (FRSC)
     */
    public function verifyDriversLicense(string $number, string $dob)
    {
        return $this->post('/identitypass/verification/frsc', [
            'number' => $number,
            'dob' => $dob,
        ]);
    }

    /**
     * Verify Nigerian Plate Number (IdentityPass)
     */
    public function verifyPlateNumber(string $number, string $country = 'NG')
    {
        return $this->post('/identitypass/verification/vehicle_verification', [
            'vehicle_number' => $number,
            'country' => $country,
        ]);
    }

    /**
     * Verify Nigerian NIN
     */
    public function verifyNIN(string $number)
    {
        // NIN verification often supports number or image. Here we use number.
        return $this->post('/identitypass/verification/nin', [
            'number' => $number,
        ]);
    }

    /**
     * Verify International Passport
     */
    public function verifyPassport(string $number, string $last_name)
    {
        return $this->post('/identitypass/verification/intl_passport', [
            'number' => $number,
            'last_name' => $last_name,
        ]);
    }

    /**
     * Verify document using image only (OCR/AI)
     */
    public function verifyDocumentImage(string $path)
    {
        $base64 = $this->getImageAsBase64($path);
        if (!$base64) {
            $this->lastError = "Could not load image for verification.";
            return null;
        }

        return $this->post('/identitypass/verification/document_verification', [
            'image' => $base64,
        ]);
    }

    /**
     * Compare Face (Profile vs Selfie)
     */
    public function compareFace(string $profilePath, string $selfiePath)
    {
        $profileBase64 = $this->getImageAsBase64($profilePath);
        $selfieBase64 = $this->getImageAsBase64($selfiePath);

        if (!$profileBase64 || !$selfieBase64) {
            $this->lastError = "Could not load images for face comparison.";
            return null;
        }

        return $this->post('/identitypass/verification/face_comparison', [
            'image_one' => $profileBase64,
            'image_two' => $selfieBase64,
        ]);
    }

    /**
     * Internal helper for POST requests
     */
    protected function post(string $endpoint, array $data)
    {
        // Add mandatory customer_id for Prembly V2
        $data['customer_id'] = 'GIGA_' . (\Illuminate\Support\Facades\Auth::id() ?? 'GUEST') . '_' . time();

        if (empty($this->apiKey) || $this->apiKey === 'MOCK') {
            Log::info("Prembly Service MOCK: $endpoint", $data);
            return [
                'status' => true,
                'data' => [
                    'verification_status' => 'VERIFIED',
                    'confidence_score' => 95.5,
                ]
            ];
        }

        try {
            $response = Http::withHeaders([
                'x-api-key' => $this->apiKey,
                'accept' => 'application/json',
                'content-type' => 'application/json',
            ])->post($this->baseUrl . $endpoint, $data);

            if ($response->successful()) {
                return $response->json();
            }

            $this->lastError = "Prembly API Error [{$response->status()}]: " . $response->body();
            Log::error($this->lastError, [
                'endpoint' => $endpoint,
                'payload' => $data,
                'response' => $response->body()
            ]);
            return null;

        } catch (\Exception $e) {
            $this->lastError = "Prembly Exception: " . $e->getMessage();
            Log::error($this->lastError, [
                'endpoint' => $endpoint,
                'payload' => $data
            ]);
            return null;
        }
    }

    /**
     * Convert stored image to base64
     */
    protected function getImageAsBase64(string $path)
    {
        if (!Storage::disk('public')->exists($path)) {
            return null;
        }

        $content = Storage::disk('public')->get($path);
        $type = mime_content_type(Storage::disk('public')->path($path));
        return 'data:' . $type . ';base64,' . base64_encode($content);
    }
}
