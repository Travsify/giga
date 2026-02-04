<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FlutterwaveTransferService
{
    protected $secretKey;
    protected $baseUrl = 'https://api.flutterwave.com/v3';

    public function __construct()
    {
        $this->secretKey = env('FLW_SECRET_KEY');
    }

    /**
     * Initiate a bank transfer.
     */
    public function initiateTransfer($data)
    {
        try {
            $response = Http::withToken($this->secretKey)
                ->post("{$this->baseUrl}/transfers", [
                    'account_bank' => $data['bank_code'],
                    'account_number' => $data['account_number'],
                    'amount' => $data['amount'],
                    'currency' => $data['currency'] ?? 'NGN',
                    'narration' => $data['narration'] ?? 'Giga Rider Payout',
                    'reference' => $data['reference'],
                    'callback_url' => env('FLW_PAYOUT_CALLBACK_URL'),
                    'debit_currency' => $data['currency'] ?? 'NGN',
                ]);

            if ($response->successful()) {
                return [
                    'success' => true,
                    'data' => $response->json('data')
                ];
            }

            Log::error('Flutterwave Transfer Error: ' . $response->body());
            return [
                'success' => false,
                'message' => $response->json('message') ?? 'Transfer failed'
            ];

        } catch (\Exception $e) {
            Log::error('Flutterwave Transfer Exception: ' . $e->getMessage());
            return [
                'success' => false,
                'message' => 'An unexpected error occurred during transfer'
            ];
        }
    }

    /**
     * Get list of supported banks.
     */
    public function getBanks($country = 'NG')
    {
        try {
            $response = Http::withToken($this->secretKey)
                ->get("{$this->baseUrl}/banks/{$country}");

            if ($response->successful()) {
                return $response->json('data');
            }

            return [];
        } catch (\Exception $e) {
            return [];
        }
    }
}
