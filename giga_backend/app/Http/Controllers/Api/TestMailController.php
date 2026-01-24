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
        
        try {
            Mail::raw('This is a test email from GIGA API to verify SMTP configuration.', function ($message) use ($to) {
                $message->to($to)
                        ->subject('GIGA SMTP Test');
            });

            return response()->json([
                'status' => 'success',
                'message' => 'Test email sent successfully to ' . $to,
                'config' => [
                    'mail_mailer' => config('mail.default'),
                    'mail_host' => config('mail.mailers.smtp.host'),
                    'mail_from' => config('mail.from.address'),
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to send test email.',
                'error' => $e->getMessage(),
                'trace' => config('app.debug') ? $e->getTraceAsString() : null
            ], 500);
        }
    }
}
