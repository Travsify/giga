<?php

namespace App\Filament\Pages;

use App\Models\AppSetting;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Pages\Page;
use Filament\Notifications\Notification;

class OperationsSettings extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-truck';
    protected static ?string $navigationGroup = 'Settings';
    protected static ?string $navigationLabel = 'Operations & Pricing';
    protected static ?int $navigationSort = 7;
    protected static string $view = 'filament.pages.settings-page';

    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill([
            'base_delivery_fee' => AppSetting::get('base_delivery_fee', 3.50),
            'price_per_km' => AppSetting::get('price_per_km', 0.50),
            'price_per_stop' => AppSetting::get('price_per_stop', 1.00),
            'surge_enabled' => AppSetting::get('surge_enabled', false),
            'surge_multiplier' => AppSetting::get('surge_multiplier', 1.0),
            'max_delivery_distance_km' => AppSetting::get('max_delivery_distance_km', 50),
            'rider_commission_percent' => AppSetting::get('rider_commission_percent', 80),
            'operating_hours_start' => AppSetting::get('operating_hours_start', '08:00'),
            'operating_hours_end' => AppSetting::get('operating_hours_end', '22:00'),
        ]);
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Pricing')
                    ->description('Configure delivery pricing')
                    ->schema([
                        Forms\Components\TextInput::make('base_delivery_fee')
                            ->label('Base Delivery Fee')
                            ->numeric()
                            ->prefix('£')
                            ->step(0.01)
                            ->required(),
                        Forms\Components\TextInput::make('price_per_km')
                            ->label('Price Per KM')
                            ->numeric()
                            ->prefix('£')
                            ->step(0.01)
                            ->required(),
                        Forms\Components\TextInput::make('price_per_stop')
                            ->label('Price Per Additional Stop')
                            ->numeric()
                            ->prefix('£')
                            ->step(0.01)
                            ->required(),
                    ])->columns(3),

                Forms\Components\Section::make('Surge Pricing')
                    ->schema([
                        Forms\Components\Toggle::make('surge_enabled')
                            ->label('Enable Surge Pricing')
                            ->helperText('Apply multiplier during peak hours')
                            ->live(),
                        Forms\Components\TextInput::make('surge_multiplier')
                            ->label('Surge Multiplier')
                            ->numeric()
                            ->step(0.1)
                            ->default(1.0)
                            ->helperText('e.g. 1.5 = 50% increase'),
                    ])->columns(2),

                Forms\Components\Section::make('Rider Commission')
                    ->schema([
                        Forms\Components\TextInput::make('rider_commission_percent')
                            ->label('Rider Commission %')
                            ->numeric()
                            ->suffix('%')
                            ->minValue(0)
                            ->maxValue(100)
                            ->helperText('Percentage of fare that goes to rider'),
                    ]),

                Forms\Components\Section::make('Service Limits')
                    ->schema([
                        Forms\Components\TextInput::make('max_delivery_distance_km')
                            ->label('Max Delivery Distance')
                            ->numeric()
                            ->suffix('km')
                            ->helperText('Maximum distance for a single delivery'),
                        Forms\Components\TimePicker::make('operating_hours_start')
                            ->label('Operating Hours Start')
                            ->seconds(false),
                        Forms\Components\TimePicker::make('operating_hours_end')
                            ->label('Operating Hours End')
                            ->seconds(false),
                    ])->columns(3),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        $data = $this->form->getState();

        foreach ($data as $key => $value) {
            AppSetting::set($key, $value, 'operations');
        }

        Notification::make()
            ->title('Operations settings saved')
            ->success()
            ->send();
    }
}
