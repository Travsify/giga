<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ResendService
{
    protected string $apiKey;
    protected string $baseUrl = 'https://api.resend.com';
    protected ?string $lastError = null;

    public function __construct()
    {
        $this->apiKey = config('services.resend.key') ?? env('RESEND_API_KEY', '');
    }

    /**
     * Get the last error message
     */
    public function getLastError(): ?string
    {
        return $this->lastError;
    }

    /**
     * Send an email using Resend API.
     */
    public function sendEmail(string $to, string $subject, string $html): bool
    {
        $this->lastError = null;
        
        if (empty($this->apiKey)) {
            $this->lastError = 'Resend API key missing. Please set RESEND_API_KEY in .env';
            Log::error($this->lastError);
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

            $this->lastError = "Resend API Error [{$response->status()}]: " . $response->body();
            Log::error($this->lastError);
            return false;

        } catch (\Exception $e) {
            $this->lastError = "Resend Service Exception: " . $e->getMessage();
            Log::error($this->lastError);
            return false;
        }
    }
}
