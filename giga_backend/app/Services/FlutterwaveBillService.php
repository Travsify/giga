<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FlutterwaveBillService
{
    protected $secretKey;
    protected $baseUrl = 'https://api.flutterwave.com/v3';

    public function __construct()
    {
        $this->secretKey = \App\Models\AppSetting::get('flutterwave_secret_key', env('FLW_SECRET_KEY'));
    }

    /**
     * Get bill categories.
     */
    public function getBillCategories()
    {
        try {
            $response = Http::withToken($this->secretKey)
                ->get("{$this->baseUrl}/bill-categories");

            if ($response->successful()) {
                return $response->json('data');
            }

            return [];
        } catch (\Exception $e) {
            Log::error('Flutterwave GetBillCategories Error: ' . $e->getMessage());
            return [];
        }
    }

    /**
     * Validate a bill service (e.g. smartcard number, meter number).
     */
    public function validateBillService($itemCode, $code, $customer)
    {
        try {
            $response = Http::withToken($this->secretKey)
                ->get("{$this->baseUrl}/bill-items/{$itemCode}/validate", [
                    'code' => $code,
                    'customer' => $customer,
                ]);

            if ($response->successful()) {
                return [
                    'success' => true,
                    'data' => $response->json('data'),
                ];
            }

            return [
                'success' => false,
                'message' => $response->json('message') ?? 'Validation failed',
            ];
        } catch (\Exception $e) {
            Log::error('Flutterwave ValidateBillService Error: ' . $e->getMessage());
            return [
                'success' => false,
                'message' => 'An unexpected error occurred during validation',
            ];
        }
    }

    /**
     * Pay a bill.
     */
    public function payBill($data)
    {
        try {
            // country, customer, amount, recurrence, type, reference
            $payload = [
                'country' => $data['country'] ?? 'NG',
                'customer' => $data['customer'],
                'amount' => $data['amount'],
                'recurrence' => 'ONCE',
                'type' => $data['type'], // e.g., 'DSTV', 'AIRTIME'
                'reference' => $data['reference'],
            ];

            $response = Http::withToken($this->secretKey)
                ->post("{$this->baseUrl}/bills", $payload);

            Log::info('Flutterwave PayBill Response: ' . $response->body());

            if ($response->successful() && $response->json('status') === 'success') {
                return [
                    'success' => true,
                    'data' => $response->json('data'),
                ];
            }

            return [
                'success' => false,
                'message' => $response->json('message') ?? 'Payment failed',
            ];
        } catch (\Exception $e) {
            Log::error('Flutterwave PayBill Error: ' . $e->getMessage());
            return [
                'success' => false,
                'message' => 'An unexpected error occurred during bill payment',
            ];
        }
    }
}
