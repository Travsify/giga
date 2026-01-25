<?php

namespace App\Filament\Pages;

use App\Models\AppSetting;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Pages\Page;
use Filament\Notifications\Notification;

class NotificationSettings extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-bell';
    protected static ?string $navigationGroup = 'Settings';
    protected static ?string $navigationLabel = 'Notifications';
    protected static ?int $navigationSort = 4;
    protected static string $view = 'filament.pages.settings-page';

    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill([
            'fcm_enabled' => AppSetting::get('fcm_enabled', true),
            'fcm_server_key' => AppSetting::get('fcm_server_key', ''),
            'delivery_notifications' => AppSetting::get('delivery_notifications', true),
            'promo_notifications' => AppSetting::get('promo_notifications', true),
            'chat_notifications' => AppSetting::get('chat_notifications', true),
        ]);
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Firebase Cloud Messaging')
                    ->description('Configure push notifications via Firebase')
                    ->schema([
                        Forms\Components\Toggle::make('fcm_enabled')
                            ->label('Enable Push Notifications')
                            ->live(),
                        Forms\Components\Textarea::make('fcm_server_key')
                            ->label('FCM Server Key')
                            ->rows(3)
                            ->helperText('Firebase Cloud Messaging server key from Firebase Console'),
                    ]),

                Forms\Components\Section::make('Notification Types')
                    ->description('Control which notifications are sent to users')
                    ->schema([
                        Forms\Components\Toggle::make('delivery_notifications')
                            ->label('Delivery Status Updates')
                            ->helperText('Notify when delivery status changes (picked up, in transit, delivered)'),
                        Forms\Components\Toggle::make('promo_notifications')
                            ->label('Promotional Notifications')
                            ->helperText('Marketing and promotional messages'),
                        Forms\Components\Toggle::make('chat_notifications')
                            ->label('Chat Messages')
                            ->helperText('Notify when rider/customer sends a message'),
                    ])->columns(3),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        $data = $this->form->getState();

        foreach ($data as $key => $value) {
            AppSetting::set($key, $value, 'notification');
        }

        Notification::make()
            ->title('Notification settings saved')
            ->success()
            ->send();
    }
}
