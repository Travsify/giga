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
            'auth_email_enabled' => AppSetting::get('auth_email_enabled', true),
            'auth_phone_enabled' => AppSetting::get('auth_phone_enabled', true),
            'email_verification_enabled' => AppSetting::get('email_verification_enabled', true),
            'phone_verification_enabled' => AppSetting::get('phone_verification_enabled', true),
            'sms_provider' => AppSetting::get('sms_provider', 'log'),
            'twilio_sid' => AppSetting::get('twilio_sid', ''),
            'twilio_token' => AppSetting::get('twilio_token', ''),
            'twilio_from' => AppSetting::get('twilio_from', ''),
            'termii_api_key' => AppSetting::get('termii_api_key', ''),
            'termii_sender_id' => AppSetting::get('termii_sender_id', 'Giga'),
            'vonage_key' => AppSetting::get('vonage_key', ''),
            'vonage_secret' => AppSetting::get('vonage_secret', ''),
            'vonage_from' => AppSetting::get('vonage_from', 'Giga'),
            'messagebird_key' => AppSetting::get('messagebird_key', ''),
            'messagebird_from' => AppSetting::get('messagebird_from', 'Giga'),
            'africastalking_username' => AppSetting::get('africastalking_username', ''),
            'africastalking_api_key' => AppSetting::get('africastalking_api_key', ''),
            'africastalking_from' => AppSetting::get('africastalking_from', ''),
            'sendchamp_api_key' => AppSetting::get('sendchamp_api_key', ''),
            'sendchamp_sender_id' => AppSetting::get('sendchamp_sender_id', 'Giga'),
            'infobip_base_url' => AppSetting::get('infobip_base_url', ''),
            'infobip_api_key' => AppSetting::get('infobip_api_key', ''),
            'infobip_from' => AppSetting::get('infobip_from', 'Giga'),
            'msg91_auth_key' => AppSetting::get('msg91_auth_key', ''),
            'msg91_template_id' => AppSetting::get('msg91_template_id', ''),
            'google_auth_enabled' => AppSetting::get('google_auth_enabled', false),
            'apple_auth_enabled' => AppSetting::get('apple_auth_enabled', false),
        ]);
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Login Methods')
                    ->schema([
                        Forms\Components\Toggle::make('auth_email_enabled')
                            ->label('Enable Email Login'),
                        Forms\Components\Toggle::make('auth_phone_enabled')
                            ->label('Enable Phone Login'),
                    ])->columns(2),

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
                                'africastalking' => 'AfricasTalking',
                                'sendchamp' => 'Sendchamp',
                                'infobip' => 'Infobip',
                                'msg91' => 'Msg91',
                            ])
                            ->required()
                            ->live(),
                    ]),

                Forms\Components\Section::make('Twilio Configuration')
                    ->visible(fn (Forms\Get $get) => $get('sms_provider') === 'twilio')
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
                    ->visible(fn (Forms\Get $get) => $get('sms_provider') === 'termii')
                    ->schema([
                        Forms\Components\TextInput::make('termii_api_key')
                            ->label('API Key')
                            ->password()
                            ->revealable(),
                        Forms\Components\TextInput::make('termii_sender_id')
                            ->label('Sender ID')
                            ->placeholder('Giga'),
                    ])->columns(2),

                Forms\Components\Section::make('Vonage Configuration')
                    ->visible(fn (Forms\Get $get) => $get('sms_provider') === 'vonage')
                    ->schema([
                        Forms\Components\TextInput::make('vonage_key')
                            ->label('API Key')
                            ->password()
                            ->revealable(),
                        Forms\Components\TextInput::make('vonage_secret')
                            ->label('API Secret')
                            ->password()
                            ->revealable(),
                        Forms\Components\TextInput::make('vonage_from')
                            ->label('Sender ID / From Number'),
                    ])->columns(3),

                Forms\Components\Section::make('MessageBird Configuration')
                    ->visible(fn (Forms\Get $get) => $get('sms_provider') === 'messagebird')
                    ->schema([
                        Forms\Components\TextInput::make('messagebird_key')
                            ->label('API Access Key')
                            ->password()
                            ->revealable(),
                        Forms\Components\TextInput::make('messagebird_from')
                            ->label('Sender Name'),
                    ])->columns(2),

                Forms\Components\Section::make('AfricasTalking Configuration')
                    ->visible(fn (Forms\Get $get) => $get('sms_provider') === 'africastalking')
                    ->schema([
                        Forms\Components\TextInput::make('africastalking_username')
                            ->label('Username')
                            ->placeholder('sandbox'),
                        Forms\Components\TextInput::make('africastalking_api_key')
                            ->label('API Key')
                            ->password()
                            ->revealable(),
                        Forms\Components\TextInput::make('africastalking_from')
                            ->label('Shortcode / Sender ID'),
                    ])->columns(3),

                Forms\Components\Section::make('Sendchamp Configuration')
                    ->visible(fn (Forms\Get $get) => $get('sms_provider') === 'sendchamp')
                    ->schema([
                        Forms\Components\TextInput::make('sendchamp_api_key')
                            ->label('Public API Key')
                            ->password()
                            ->revealable(),
                        Forms\Components\TextInput::make('sendchamp_sender_id')
                            ->label('Sender Name'),
                    ])->columns(2),

                Forms\Components\Section::make('Infobip Configuration')
                    ->visible(fn (Forms\Get $get) => $get('sms_provider') === 'infobip')
                    ->schema([
                        Forms\Components\TextInput::make('infobip_base_url')
                            ->label('Base API URL')
                            ->placeholder('xyz.api.infobip.com'),
                        Forms\Components\TextInput::make('infobip_api_key')
                            ->label('API Key')
                            ->password()
                            ->revealable(),
                        Forms\Components\TextInput::make('infobip_from')
                            ->label('Sender ID'),
                    ])->columns(3),

                Forms\Components\Section::make('Msg91 Configuration')
                    ->visible(fn (Forms\Get $get) => $get('sms_provider') === 'msg91')
                    ->schema([
                        Forms\Components\TextInput::make('msg91_auth_key')
                            ->label('Auth Key')
                            ->password()
                            ->revealable(),
                        Forms\Components\TextInput::make('msg91_template_id')
                            ->label('OTP Template ID'),
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
