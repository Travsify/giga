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
            Log::error('Resend API key missing. Please set RESEND_API_KEY in .env');
            return false;
        }

        try {
            $fromEmail = env('RESEND_FROM_EMAIL', 'onboarding@resend.dev');
            $fromName = env('RESEND_FROM_NAME', 'Giga Logistics');
            
            Log::info("Attempting to send email to: {$to} from: {$fromEmail}");
            
            $response = Http::withToken($this->apiKey)
                ->post("{$this->baseUrl}/emails", [
                    'from' => "{$fromName} <{$fromEmail}>",
                    'to' => [$to],
                    'subject' => $subject,
                    'html' => $html,
                ]);

            if ($response->successful()) {
                Log::info("Resend Email sent successfully to: {$to}");
                return true;
            }

            Log::error("Resend API Error [{$response->status()}]: " . $response->body());
            return false;

        } catch (\Exception $e) {
            Log::error("Resend Service Exception: " . $e->getMessage());
            return false;
        }
    }
}
