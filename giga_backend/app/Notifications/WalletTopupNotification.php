<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class WalletTopupNotification extends Notification implements ShouldQueue
{
    use Queueable;

    protected $amount;
    protected $balance;
    protected $currency;
    protected $provider;

    /**
     * Create a new notification instance.
     */
    public function __construct($amount, $balance, $currency, $provider)
    {
        $this->amount = $amount;
        $this->balance = $balance;
        $this->currency = $currency;
        $this->provider = $provider;
    }

    /**
     * Get the notification's delivery channels.
     *
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return ['mail', 'database'];
    }

    /**
     * Get the mail representation of the notification.
     */
    public function toMail(object $notifiable): MailMessage
    {
        $appName = config('app.name', 'Giga Logistics');
        return (new MailMessage)
            ->subject("Wallet Top-up Successful - $appName")
            ->greeting('Hello ' . $notifiable->name . '!')
            ->line('Your wallet has been successfully credited.')
            ->line('Amount: ' . $this->currency . ' ' . number_format($this->amount, 2))
            ->line('Provider: ' . ucfirst($this->provider))
            ->line('New Balance: ' . $this->currency . ' ' . number_format($this->balance, 2))
            ->action('View My Wallet', url('/wallet')) 
            ->line("Thank you for choosing $appName!");
    }

    /**
     * Get the array representation of the notification.
     *
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        return [
            'title' => 'Wallet Credited',
            'message' => "Your wallet has been credited with {$this->currency} " . number_format($this->amount, 2),
            'amount' => $this->amount,
            'new_balance' => $this->balance,
            'currency' => $this->currency,
            'type' => 'wallet_topup',
        ];
    }
}
