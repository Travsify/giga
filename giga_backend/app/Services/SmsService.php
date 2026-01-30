<?php

namespace App\Services;

use App\Models\AppSetting;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class SmsService
{
    protected $driver;

    public function __construct()
    {
        $this->driver = AppSetting::get('sms_provider') ?? env('SMS_DRIVER', 'log');
    }

    public function send($to, $message)
    {
        Log::info("Sending SMS via [{$this->driver}] to {$to}: {$message}");

        try {
            switch ($this->driver) {
                case 'twilio':
                    return $this->sendTwilio($to, $message);
                case 'termii':
                    return $this->sendTermii($to, $message);
                case 'vonage': // Now Nexmo
                    return $this->sendVonage($to, $message);
                case 'messagebird':
                    return $this->sendMessageBird($to, $message);
                case 'log':
                    return true;
                default:
                    Log::error("Unknown SMS driver: {$this->driver}");
                    return false;
            }
        } catch (\Exception $e) {
            Log::error("SMS Send Failed ({$this->driver}): " . $e->getMessage());
            return false;
        }
    }

    protected function sendTwilio($to, $message)
    {
        $sid = AppSetting::get('twilio_sid') ?? env('TWILIO_SID');
        $token = AppSetting::get('twilio_token') ?? env('TWILIO_TOKEN');
        $from = AppSetting::get('twilio_from') ?? env('TWILIO_FROM');

        $url = "https://api.twilio.com/2010-04-01/Accounts/{$sid}/Messages.json";

        $response = Http::withBasicAuth($sid, $token)->asForm()->post($url, [
            'From' => $from,
            'To' => $to,
            'Body' => $message,
        ]);

        if ($response->successful()) {
            return true;
        }
        
        Log::error("Twilio Error: " . $response->body());
        return false;
    }

    protected function sendTermii($to, $message)
    {
        $key = AppSetting::get('termii_api_key') ?? env('TERMII_API_KEY');
        $from = AppSetting::get('termii_sender_id') ?? env('TERMII_SENDER_ID', 'Giga');

        $response = Http::post('https://api.ng.termii.com/api/sms/send', [
            'to' => $to,
            'from' => $from,
            'sms' => $message,
            'type' => 'plain',
            'channel' => 'generic', // or 'dnd'
            'api_key' => $key,
        ]);

        if ($response->successful()) {
            return true;
        }
        
        Log::error("Termii Error: " . $response->body());
        return false;
    }

    protected function sendVonage($to, $message)
    {
        // Nexmo / Vonage
        $key = AppSetting::get('vonage_key') ?? env('VONAGE_KEY');
        $secret = AppSetting::get('vonage_secret') ?? env('VONAGE_SECRET');
        $from = AppSetting::get('vonage_from') ?? env('VONAGE_FROM', 'Giga');

        $response = Http::post('https://rest.nexmo.com/sms/json', [
            'api_key' => $key,
            'api_secret' => $secret,
            'to' => str_replace('+', '', $to), // Vonage requires no +
            'from' => $from,
            'text' => $message,
        ]);

        if ($response->successful()) {
            $data = $response->json();
            if (isset($data['messages'][0]['status']) && $data['messages'][0]['status'] == '0') {
                return true;
            }
            Log::error("Vonage Error Details: " . json_encode($data));
        }
        
        Log::error("Vonage HTTP Error: " . $response->body());
        return false;
    }

    protected function sendMessageBird($to, $message)
    {
        $key = AppSetting::get('messagebird_key') ?? env('MESSAGEBIRD_KEY');
        $from = AppSetting::get('messagebird_from') ?? env('MESSAGEBIRD_FROM', 'Giga');

        $response = Http::withHeaders([
            'Authorization' => "AccessKey {$key}"
        ])->post('https://rest.messagebird.com/messages', [
            'originator' => $from,
            'recipients' => str_replace('+', '', $to), // Usually no +
            'body' => $message,
        ]);

        if ($response->successful()) {
            return true;
        }

        Log::error("MessageBird Error: " . $response->body());
        return false;
    }
}
