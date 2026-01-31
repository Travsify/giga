<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;

use App\Services\SmsService;

class TestMailController extends Controller
{
    protected $smsService;

    public function __construct(SmsService $smsService)
    {
        $this->smsService = $smsService;
    }

    public function sendTestSms(Request $request)
    {
        $phone = $request->query('phone');
        if (!$phone) {
            return response()->json(['status' => 'error', 'message' => 'Phone number is required. Usage: /api/test-sms?phone=+1234567890'], 400);
        }

        $driver = \App\Models\AppSetting::get('sms_provider') ?? env('SMS_DRIVER', 'log');
        $sent = $this->smsService->send($phone, "GIGA SMS Test - Your system is correctly configured on driver: [{$driver}].");

        if ($sent) {
            return response()->json([
                'status' => 'success',
                'message' => 'Test SMS sent successfully to ' . $phone,
                'driver' => $driver
            ]);
        }

        return response()->json([
            'status' => 'error',
            'message' => 'Failed to send test SMS. Check laravel.log for details.',
            'error_details' => $this->smsService->getLastError(),
            'driver' => $driver
        ], 500);
    }

    public function sendTestMail(Request $request)
    {
        $to = $request->query('email', 'info@usegiga.site');
        
        $config = [
            'mail_mailer' => config('mail.default'),
            'mail_host' => config('mail.mailers.smtp.host'),
            'mail_port' => config('mail.mailers.smtp.port'),
            'mail_encryption' => config('mail.mailers.smtp.encryption'),
            'mail_username' => config('mail.mailers.smtp.username'),
            'mail_from' => config('mail.from.address'),
            'mail_password_hint' => substr(config('mail.mailers.smtp.password') ?? '', 0, 2) . '...' . substr(config('mail.mailers.smtp.password') ?? '', -2),
            'flw_keys_set' => [
                'public' => !empty(\App\Models\AppSetting::get('flutterwave_public_key')),
                'secret' => !empty(\App\Models\AppSetting::get('flutterwave_secret_key')),
                'encryption' => !empty(\App\Models\AppSetting::get('flutterwave_encryption_key')),
            ],
            'env_overrides' => [
                'MAIL_HOST' => env('MAIL_HOST'),
                'MAIL_USERNAME' => env('MAIL_USERNAME'),
                'DB_MAIL_HOST' => \App\Models\AppSetting::where('key', 'mail_host')->first()?->value,
            ],
            'all_settings' => \App\Models\AppSetting::all()->mapWithKeys(function($s) { 
                return [$s->key => $s->is_sensitive ? 'MASKED' : $s->value]; 
            }),
            'last_migrations' => \Illuminate\Support\Facades\DB::table('migrations')->orderBy('id', 'desc')->limit(5)->pluck('migration'),
        ];

        try {
            Mail::raw('This is a test email from GIGA API to verify SMTP configuration.', function ($message) use ($to) {
                $message->to($to)
                        ->subject('GIGA SMTP Test');
            });

            return response()->json([
                'status' => 'success',
                'message' => 'Test email sent successfully to ' . $to,
                'config' => $config
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to send test email.',
                'error' => $e->getMessage(),
                'config' => $config,
                'trace' => $e->getTraceAsString()
            ], 500);
        }
    }
}
