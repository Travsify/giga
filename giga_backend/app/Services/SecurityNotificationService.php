<?php

namespace App\Services;

use App\Models\AppSetting;
use App\Models\User;
use Illuminate\Support\Facades\Log;

class SecurityNotificationService
{
    protected ResendService $resend;

    public function __construct(ResendService $resend)
    {
        $this->resend = $resend;
    }

    /**
     * Notify user and admin about a transaction.
     */
    public function notifyTransaction($transaction)
    {
        $wallet = $transaction->wallet;
        $user = $wallet->user;
        $adminEmail = AppSetting::get('admin_alert_email', '');

        $type = strtoupper($transaction->type); // CREDIT or DEBIT
        $amount = number_format($transaction->amount, 2);
        $currency = $transaction->currency;
        $description = $transaction->description;
        $date = $transaction->created_at->format('M d, Y H:i');

        $subject = "Transaction Alert: {$type} - {$currency} {$amount}";
        
        $html = "
            <div style='font-family: sans-serif; color: #333;'>
                <h2 style='color: " . ($type === 'CREDIT' ? '#4caf50' : '#f44336') . "'>Transaction Alert</h2>
                <p>Hello <strong>{$user->name}</strong>,</p>
                <p>A transaction has occurred on your Giga Wallet.</p>
                <table style='width: 100%; border-collapse: collapse;'>
                    <tr><td style='padding: 8px; border-bottom: 1px solid #eee;'><strong>Type:</strong></td><td style='padding: 8px; border-bottom: 1px solid #eee;'>{$type}</td></tr>
                    <tr><td style='padding: 8px; border-bottom: 1px solid #eee;'><strong>Amount:</strong></td><td style='padding: 8px; border-bottom: 1px solid #eee;'>{$currency} {$amount}</td></tr>
                    <tr><td style='padding: 8px; border-bottom: 1px solid #eee;'><strong>Description:</strong></td><td style='padding: 8px; border-bottom: 1px solid #eee;'>{$description}</td></tr>
                    <tr><td style='padding: 8px; border-bottom: 1px solid #eee;'><strong>Date:</strong></td><td style='padding: 8px; border-bottom: 1px solid #eee;'>{$date}</td></tr>
                </table>
                <p style='margin-top: 20px; font-size: 12px; color: #666;'>If you do not recognize this transaction, please contact support immediately.</p>
            </div>
        ";

        // Send to User
        $this->resend->sendEmail($user->email, $subject, $html);

        // Send to Admin if configured
        if (!empty($adminEmail)) {
            $adminSubject = "[Admin Alert] Transaction: {$user->name} ({$user->email}) - {$type} {$amount}";
            $this->resend->sendEmail($adminEmail, $adminSubject, $html);
        }
    }

    /**
     * Notify user and admin about an authentication event.
     */
    public function notifyAuthEvent(User $user, string $eventType)
    {
        $adminEmail = AppSetting::get('admin_alert_email', '');
        $date = now()->format('M d, Y H:i');
        $ip = request()->ip();
        $userAgent = request()->userAgent();

        $action = $eventType === 'signup' ? 'Account Created' : 'New Login';
        $subject = "Security Alert: {$action} - Giga Logistics";

        $html = "
            <div style='font-family: sans-serif; color: #333;'>
                <h2 style='color: #2196f3'>Security Alert</h2>
                <p>Hello <strong>{$user->name}</strong>,</p>
                <p>This is to notify you of a <strong>{$action}</strong> on your Giga Logistics account.</p>
                <div style='background: #f5f5f5; padding: 15px; border-radius: 8px;'>
                    <p style='margin: 0;'><strong>Date:</strong> {$date}</p>
                    <p style='margin: 5px 0 0 0;'><strong>IP Address:</strong> {$ip}</p>
                    <p style='margin: 5px 0 0 0;'><strong>Device:</strong> {$userAgent}</p>
                </div>
                <p style='margin-top: 20px; font-size: 12px; color: #666;'>If this was not you, please secure your account by resetting your password immediately.</p>
            </div>
        ";

        // Send to User
        $this->resend->sendEmail($user->email, $subject, $html);

        // Send to Admin if configured
        if (!empty($adminEmail)) {
            $adminSubject = "[Admin Alert] {$action}: {$user->name} ({$user->email})";
            $this->resend->sendEmail($adminEmail, $adminSubject, $html);
        }
    }
}
