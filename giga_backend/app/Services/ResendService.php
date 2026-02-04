<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ResendService
{
    protected string $apiKey;
    protected string $baseUrl = 'https://api.resend.com';

    public function __construct()
    {
        $this->apiKey = config('services.resend.key') ?? env('RESEND_API_KEY', '');
    }

    /**
     * Send an email using Resend API.
     */
    public function sendEmail(string $to, string $subject, string $html): bool
    {
        if (empty($this->apiKey)) {
            Log::error('Resend API key missing.');
            return false;
        }

        try {
            $response = Http::withToken($this->apiKey)
                ->post("{$this->baseUrl}/emails", [
                    'from' => 'Giga Logistics <onboarding@resend.dev>', // Update to verified domain in prod
                    'to' => [$to],
                    'subject' => $subject,
                    'html' => $html,
                ]);

            if ($response->successful()) {
                Log::info("Resend Email sent to: {$to}");
                return true;
            }

            Log::error("Resend API Error: " . $response->body());
            return false;

        } catch (\Exception $e) {
            Log::error("Resend Service Exception: " . $e->getMessage());
            return false;
        }
    }
}
