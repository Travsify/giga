<?php

namespace App\Filament\Pages;

use App\Models\AppSetting;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Pages\Page;
use Filament\Notifications\Notification;

class PaymentSettings extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-credit-card';
    protected static ?string $navigationGroup = 'Settings';
    protected static ?string $navigationLabel = 'Payments';
    protected static ?int $navigationSort = 3;
    protected static string $view = 'filament.pages.settings-page';

    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill([
            'currency' => AppSetting::get('currency', 'GBP'),
            'currency_symbol' => AppSetting::get('currency_symbol', '£'),
            'stripe_enabled' => AppSetting::get('stripe_enabled', true),
            'stripe_public_key' => AppSetting::get('stripe_public_key', ''),
            'stripe_secret_key' => AppSetting::get('stripe_secret_key', ''),
            'stripe_webhook_secret' => AppSetting::get('stripe_webhook_secret', ''),
            'paystack_enabled' => AppSetting::get('paystack_enabled', false),
            'paystack_public_key' => AppSetting::get('paystack_public_key', ''),
            'paystack_secret_key' => AppSetting::get('paystack_secret_key', ''),
            'flutterwave_enabled' => AppSetting::get('flutterwave_enabled', false),
            'flutterwave_public_key' => AppSetting::get('flutterwave_public_key', ''),
            'flutterwave_secret_key' => AppSetting::get('flutterwave_secret_key', ''),
            'flutterwave_encryption_key' => AppSetting::get('flutterwave_encryption_key', ''),
            'paypal_enabled' => AppSetting::get('paypal_enabled', false),
            'paypal_client_id' => AppSetting::get('paypal_client_id', ''),
            'paypal_secret' => AppSetting::get('paypal_secret', ''),
            'wallet_enabled' => AppSetting::get('wallet_enabled', true),
            'cod_enabled' => AppSetting::get('cod_enabled', true),
        ]);
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Currency')
                    ->schema([
                        Forms\Components\Select::make('currency')
                            ->label('Default Currency')
                            ->options([
                                'GBP' => 'British Pound (GBP)',
                                'USD' => 'US Dollar (USD)',
                                'EUR' => 'Euro (EUR)',
                                'NGN' => 'Nigerian Naira (NGN)',
                            ])
                            ->required(),
                        Forms\Components\TextInput::make('currency_symbol')
                            ->label('Currency Symbol')
                            ->required()
                            ->maxLength(5),
                    ])->columns(2),

                Forms\Components\Section::make('Stripe')
                    ->description('Stripe payment gateway configuration')
                    ->schema([
                        Forms\Components\Toggle::make('stripe_enabled')
                            ->label('Enable Stripe Payments')
                            ->live(),
                        Forms\Components\TextInput::make('stripe_public_key')
                            ->label('Publishable Key')
                            ->placeholder('pk_test_...')
                            ->columnSpan(2),
                        Forms\Components\TextInput::make('stripe_secret_key')
                            ->label('Secret Key')
                            ->password()
                            ->revealable()
                            ->placeholder('sk_test_...'),
                        Forms\Components\TextInput::make('stripe_webhook_secret')
                            ->label('Webhook Secret')
                            ->password()
                            ->revealable()
                            ->placeholder('whsec_...'),
                    ])->columns(2),

                Forms\Components\Section::make('Paystack')
                    ->description('Paystack payment gateway configuration')
                    ->schema([
                        Forms\Components\Toggle::make('paystack_enabled')
                            ->label('Enable Paystack Payments')
                            ->live(),
                        Forms\Components\TextInput::make('paystack_public_key')
                            ->label('Public Key')
                            ->placeholder('pk_test_...')
                            ->columnSpan(2),
                        Forms\Components\TextInput::make('paystack_secret_key')
                            ->label('Secret Key')
                            ->password()
                            ->revealable()
                            ->placeholder('sk_test_...'),
                    ])->columns(2),

                Forms\Components\Section::make('Flutterwave')
                    ->description('Flutterwave payment gateway configuration')
                    ->schema([
                        Forms\Components\Toggle::make('flutterwave_enabled')
                            ->label('Enable Flutterwave Payments')
                            ->live(),
                        Forms\Components\TextInput::make('flutterwave_public_key')
                            ->label('Public Key')
                            ->placeholder('FLWPUBK_TEST-...')
                            ->columnSpan(2),
                        Forms\Components\TextInput::make('flutterwave_secret_key')
                            ->label('Secret Key')
                            ->password()
                            ->revealable()
                            ->placeholder('FLWSECK_TEST-...'),
                        Forms\Components\TextInput::make('flutterwave_encryption_key')
                            ->label('Encryption Key')
                            ->password()
                            ->revealable()
                            ->placeholder('FLWSECK_TEST-...'),
                    ])->columns(2),

                Forms\Components\Section::make('PayPal')
                    ->schema([
                        Forms\Components\Toggle::make('paypal_enabled')
                            ->label('Enable PayPal Payments')
                            ->live(),
                        Forms\Components\TextInput::make('paypal_client_id')
                            ->label('Client ID'),
                        Forms\Components\TextInput::make('paypal_secret')
                            ->label('Secret')
                            ->password()
                            ->revealable(),
                    ])->columns(2),

                Forms\Components\Section::make('Other Payment Methods')
                    ->schema([
                        Forms\Components\Toggle::make('wallet_enabled')
                            ->label('Enable In-App Wallet')
                            ->helperText('Allow users to top up and pay with wallet balance'),
                        Forms\Components\Toggle::make('cod_enabled')
                            ->label('Enable Cash on Delivery'),
                    ])->columns(2),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        $data = $this->form->getState();

        foreach ($data as $key => $value) {
            AppSetting::set($key, $value, 'payment');
        }

        Notification::make()
            ->title('Payment settings saved')
            ->success()
            ->send();
    }
}
