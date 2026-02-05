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
        // ... (existing code for raw mail) ...
        $to = $request->query('email', 'info@usegiga.site');
        // ...
        try {
            Mail::raw('This is a test email from GIGA.', function ($message) use ($to) {
                $message->to($to)->subject('GIGA SMTP Test (Raw)');
            });
            return response()->json(['status' => 'success', 'message' => 'Raw email sent.']);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }

    public function sendTestView(Request $request)
    {
        $to = $request->query('email', 'info@usegiga.site');
        
        try {
            // MIMIC EmailVerificationController EXACTLY
            \Illuminate\Support\Facades\Mail::forgetMailers();
            
            \Illuminate\Support\Facades\Log::info("Test View: Sending to $to");
            
            \Illuminate\Support\Facades\Mail::send('emails.verify', ['code' => '123456', 'name' => 'Test User'], function ($message) use ($to) {
                $message->to($to)
                        ->subject('GIGA SMTP Test (View)');
            });

            return response()->json([
                'status' => 'success',
                'message' => 'View-based email sent successfully to ' . $to,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to send view-based email.',
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ], 500);
        }
    }

    public function liveSmtpTest(Request $request)
    {
        $host = $request->query('host', config('mail.mailers.smtp.host'));
        $port = $request->query('port', config('mail.mailers.smtp.port'));
        $user = $request->query('user', config('mail.mailers.smtp.username'));
        $pass = $request->query('pass', config('mail.mailers.smtp.password'));
        $enc  = $request->query('enc', config('mail.mailers.smtp.encryption'));
        $to   = $request->query('to', 'info@usegiga.site');

        $results = [
            'config_used' => [
                'host' => $host,
                'port' => $port,
                'user' => $user,
                'enc' => $enc,
            ],
            'checks' => []
        ];

        // 1. Connection Check
        $timeout = 5;
        $preflight = @fsockopen($host, $port, $errno, $errstr, $timeout);
        if ($preflight) {
            $results['checks']['connection'] = "SUCCESS: Connected to $host:$port";
            fclose($preflight);
        } else {
            $results['checks']['connection'] = "FAILED: $errstr ($errno)";
            return response()->json($results, 500);
        }

        // 2. Dynamic Mailer Config
        try {
            config([
                'mail.mailers.smtp_live' => [
                    'transport' => 'smtp',
                    'host' => $host,
                    'port' => $port,
                    'encryption' => $enc,
                    'username' => $user,
                    'password' => $pass,
                ]
            ]);

            Mail::mailer('smtp_live')->raw("Live SMTP Test from GIGA Diagnostics", function ($message) use ($to) {
                $message->to($to)->subject('GIGA Live SMTP Test');
            });

            $results['checks']['send'] = "SUCCESS: Email accepted by $host";
            return response()->json($results);
        } catch (\Exception $e) {
            $results['checks']['send'] = "FAILED: " . $e->getMessage();
            return response()->json($results, 500);
        }
    }
    public function resendDiag(Request $request)
    {
        $to = $request->query('email', 'info@usegiga.site');
        $apiKey = config('resend.api_key') ?: env('RESEND_API_KEY');
        $from = config('mail.from.address');
        
        $results['raw_env'] = [
            'MAIL_MAILER' => env('MAIL_MAILER'),
            'MAIL_FROM_ADDRESS' => env('MAIL_FROM_ADDRESS'),
            'RESEND_API_KEY_EXISTS' => env('RESEND_API_KEY') ? 'YES' : 'NO',
        ];

        try {
            \Illuminate\Support\Facades\Log::info("Resend Diag: Attempting send to $to from $from");
            
            Mail::mailer('resend')->raw('Resend Diagnostic Test from GIGA.', function ($message) use ($to, $from) {
                $message->to($to)
                        ->from($from)
                        ->subject('GIGA Resend Diagnostic (Verification)');
            });

            $results['send_status'] = 'SUCCESS';
            $results['message'] = 'Email accepted by Resend API.';
        } catch (\Throwable $e) {
            $results['send_status'] = 'FAILED';
            $results['error'] = $e->getMessage();
            $results['error_type'] = get_class($e);
            
            if (str_contains($e->getMessage(), 'unverified')) {
                $results['interpretation'] = "Your 'From' address ($from) is NOT verified in the Resend dashboard. You can only send from verified domains.";
            }
        }

        return response()->json($results);
    }

    public function envCheck(Request $request)
    {
        $prefixes = ['MAIL_', 'RESEND_', 'APP_', 'PREMBLY_', 'DVLA_', 'FLW_'];
        $env = [];
        
        foreach ($_SERVER as $key => $value) {
            foreach ($prefixes as $prefix) {
                if (str_starts_with($key, $prefix)) {
                    // Censor sensitive data
                    if (str_contains($key, 'KEY') || str_contains($key, 'PASS') || str_contains($key, 'SECRET')) {
                        $env[$key] = substr((string)$value, 0, 4) . '... (len: ' . strlen((string)$value) . ')';
                    } else {
                        $env[$key] = $value;
                    }
                }
            }
        }

        return response()->json([
            'version' => '1.1.8',
            'env_vars' => $env,
            'config_mail_default' => config('mail.default'),
            'config_mail_from' => config('mail.from.address'),
        ]);
    }

    public function syncMailSettings(Request $request)
    {
        if (!\Illuminate\Support\Facades\Schema::hasTable('app_settings')) {
            return response()->json(['error' => 'app_settings table not found'], 404);
        }

        $changes = [];
        $settings = [
            'mail_mailer' => env('MAIL_MAILER'),
            'mail_from_address' => env('MAIL_FROM_ADDRESS'),
            'resend_api_key' => env('RESEND_API_KEY'),
        ];

        foreach ($settings as $key => $value) {
            if ($value) {
                \App\Models\AppSetting::set($key, $value);
                $changes[$key] = $value;
            }
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Database settings synced with Environment variables.',
            'synced' => $changes
        ]);
    }
    public function viewLogs(Request $request)
    {
        $logFile = storage_path('logs/laravel.log');
        if (!file_exists($logFile)) {
            return response()->json(['status' => 'error', 'message' => 'Log file not found.'], 404);
        }

        $lines = shell_exec('tail -n 100 ' . escapeshellarg($logFile));
        return response()->json([
            'status' => 'success',
            'file' => $logFile,
            'content' => $lines
        ]);
    }

    /**
     * Test the custom ResendService (direct HTTP API)
     */
    public function testResendService(Request $request)
    {
        $to = $request->query('email', 'info@usegiga.site');
        
        $results = [
            'service' => 'ResendService (Direct HTTP API)',
            'to' => $to,
            'config' => [
                'RESEND_API_KEY_EXISTS' => config('services.resend.key') ? 'YES' : (env('RESEND_API_KEY') ? 'YES (from env)' : 'NO'),
                'RESEND_FROM_EMAIL' => env('RESEND_FROM_EMAIL', 'onboarding@resend.dev'),
                'RESEND_FROM_NAME' => env('RESEND_FROM_NAME', 'Giga Logistics'),
            ],
        ];
        
        try {
            $resendService = app(\App\Services\ResendService::class);
            $html = "<h3>Test Email</h3><p>This is a test email from GIGA's custom ResendService.</p><p>Time: " . now() . "</p>";
            $sent = $resendService->sendEmail($to, 'GIGA ResendService Test', $html);
            
            if ($sent) {
                $results['status'] = 'SUCCESS';
                $results['message'] = "Email sent successfully to {$to}";
            } else {
                $results['status'] = 'FAILED';
                $results['api_error'] = $resendService->getLastError();
                $results['message'] = 'Email sending failed. See api_error for details.';
            }
        } catch (\Throwable $e) {
            $results['status'] = 'ERROR';
            $results['error'] = $e->getMessage();
            $results['error_type'] = get_class($e);
        }
        
        return response()->json($results);
    }
}
