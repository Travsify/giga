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
                case 'africastalking':
                    return $this->sendAfricasTalking($to, $message);
                case 'sendchamp':
                    return $this->sendSendchamp($to, $message);
                case 'infobip':
                    return $this->sendInfobip($to, $message);
                case 'msg91':
                    return $this->sendMsg91($to, $message);
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

    protected function sendAfricasTalking($to, $message)
    {
        $username = AppSetting::get('africastalking_username') ?? env('AFRICASTALKING_USERNAME');
        $apiKey = AppSetting::get('africastalking_api_key') ?? env('AFRICASTALKING_API_KEY');
        $from = AppSetting::get('africastalking_from') ?? env('AFRICASTALKING_FROM');

        $response = Http::withHeaders([
            'apiKey' => $apiKey,
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Accept' => 'application/json',
        ])->asForm()->post('https://api.africastalking.com/version1/messaging', [
            'username' => $username,
            'to' => $to,
            'message' => $message,
            'from' => $from,
        ]);

        if ($response->successful()) {
            return true;
        }

        Log::error("AfricasTalking Error: " . $response->body());
        return false;
    }

    protected function sendSendchamp($to, $message)
    {
        $apiKey = AppSetting::get('sendchamp_api_key') ?? env('SENDCHAMP_API_KEY');
        $senderId = AppSetting::get('sendchamp_sender_id') ?? env('SENDCHAMP_SENDER_ID', 'Giga');

        $response = Http::withToken($apiKey)->post('https://api.sendchamp.com/api/v1/sms/send', [
            'to' => [$to],
            'message' => $message,
            'sender_name' => $senderId,
            'route' => 'non_dnd', // or dnd, international
        ]);

        if ($response->successful()) {
            return true;
        }

        Log::error("Sendchamp Error: " . $response->body());
        return false;
    }

    protected function sendInfobip($to, $message)
    {
        $baseUrl = AppSetting::get('infobip_base_url') ?? env('INFOBIP_BASE_URL');
        $apiKey = AppSetting::get('infobip_api_key') ?? env('INFOBIP_API_KEY');
        $from = AppSetting::get('infobip_from') ?? env('INFOBIP_FROM', 'Giga');

        $response = Http::withHeaders([
            'Authorization' => "App {$apiKey}",
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
        ])->post("https://{$baseUrl}/sms/2/text/advanced", [
            'messages' => [
                [
                    'from' => $from,
                    'destinations' => [['to' => $to]],
                    'text' => $message,
                ]
            ],
        ]);

        if ($response->successful()) {
            return true;
        }

        Log::error("Infobip Error: " . $response->body());
        return false;
    }

    protected function sendMsg91($to, $message)
    {
        $authKey = AppSetting::get('msg91_auth_key') ?? env('MSG91_AUTH_KEY');
        $templateId = AppSetting::get('msg91_template_id') ?? env('MSG91_TEMPLATE_ID');

        $response = Http::withHeaders([
            'authkey' => $authKey,
            'Content-Type' => 'application/json',
        ])->post('https://api.msg91.com/api/v5/otp', [
            'template_id' => $templateId,
            'mobile' => str_replace('+', '', $to),
            'authkey' => $authKey,
        ]);

        // Note: Msg91 OTP API is slightly different from bulk SMS.
        // If they want general SMS, we'd use /api/v5/flow/
        
        if ($response->successful()) {
            return true;
        }

        Log::error("Msg91 Error: " . $response->body());
        return false;
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
            'to' => str_replace('+', '', $to),
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
