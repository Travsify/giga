<?php

namespace App\Filament\Pages;

use App\Models\AppSetting;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Pages\Page;
use Filament\Notifications\Notification;

class AuthSettings extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-key';
    protected static ?string $navigationGroup = 'Settings';
    protected static ?string $navigationLabel = 'Authentication';
    protected static ?int $navigationSort = 2;
    protected static string $view = 'filament.pages.settings-page';

    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill([
            'email_verification_enabled' => AppSetting::get('email_verification_enabled', true),
            'phone_verification_enabled' => AppSetting::get('phone_verification_enabled', true),
            'sms_provider' => AppSetting::get('sms_provider', 'log'),
            'twilio_sid' => AppSetting::get('twilio_sid', ''),
            'twilio_token' => AppSetting::get('twilio_token', ''),
            'twilio_from' => AppSetting::get('twilio_from', ''),
            'termii_api_key' => AppSetting::get('termii_api_key', ''),
            'termii_sender_id' => AppSetting::get('termii_sender_id', 'Giga'),
            'google_auth_enabled' => AppSetting::get('google_auth_enabled', false),
            'apple_auth_enabled' => AppSetting::get('apple_auth_enabled', false),
        ]);
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Verification Settings')
                    ->schema([
                        Forms\Components\Toggle::make('email_verification_enabled')
                            ->label('Require Email Verification'),
                        Forms\Components\Toggle::make('phone_verification_enabled')
                            ->label('Require Phone Verification'),
                    ])->columns(2),

                Forms\Components\Section::make('SMS Provider')
                    ->description('Configure SMS/OTP provider for phone verification')
                    ->schema([
                        Forms\Components\Select::make('sms_provider')
                            ->label('SMS Provider')
                            ->options([
                                'log' => 'Log Only (Development)',
                                'twilio' => 'Twilio',
                                'vonage' => 'Vonage (Nexmo)',
                                'termii' => 'Termii',
                                'messagebird' => 'MessageBird',
                            ])
                            ->required()
                            ->live(),
                    ]),

                Forms\Components\Section::make('Twilio Configuration')
                    ->schema([
                        Forms\Components\TextInput::make('twilio_sid')
                            ->label('Account SID')
                            ->password()
                            ->revealable(),
                        Forms\Components\TextInput::make('twilio_token')
                            ->label('Auth Token')
                            ->password()
                            ->revealable(),
                        Forms\Components\TextInput::make('twilio_from')
                            ->label('From Phone Number')
                            ->placeholder('+1234567890'),
                    ])->columns(3),

                Forms\Components\Section::make('Termii Configuration')
                    ->schema([
                        Forms\Components\TextInput::make('termii_api_key')
                            ->label('API Key')
                            ->password()
                            ->revealable(),
                        Forms\Components\TextInput::make('termii_sender_id')
                            ->label('Sender ID')
                            ->placeholder('Giga'),
                    ])->columns(2),

                Forms\Components\Section::make('Social Login')
                    ->schema([
                        Forms\Components\Toggle::make('google_auth_enabled')
                            ->label('Enable Google Sign-In'),
                        Forms\Components\Toggle::make('apple_auth_enabled')
                            ->label('Enable Apple Sign-In'),
                    ])->columns(2),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        $data = $this->form->getState();

        foreach ($data as $key => $value) {
            AppSetting::set($key, $value, 'auth');
        }

        Notification::make()
            ->title('Authentication settings saved')
            ->success()
            ->send();
    }
}
