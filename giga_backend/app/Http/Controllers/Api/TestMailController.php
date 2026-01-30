<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;

class TestMailController extends Controller
{
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
