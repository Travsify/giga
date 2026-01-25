<?php

namespace App\Filament\Pages;

use App\Models\AppSetting;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Pages\Page;
use Filament\Actions\Action;
use Filament\Notifications\Notification;

class AppConfigSettings extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-cog-6-tooth';
    protected static ?string $navigationGroup = 'Settings';
    protected static ?string $navigationLabel = 'App Configuration';
    protected static ?int $navigationSort = 1;
    protected static string $view = 'filament.pages.settings-page';

    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill([
            'app_name' => AppSetting::get('app_name', 'Giga'),
            'app_tagline' => AppSetting::get('app_tagline', ''),
            'app_version' => AppSetting::get('app_version', '1.0.0'),
            'min_app_version' => AppSetting::get('min_app_version', '1.0.0'),
            'maintenance_mode' => AppSetting::get('maintenance_mode', false),
            'maintenance_message' => AppSetting::get('maintenance_message', ''),
            'splash_image_url' => AppSetting::get('splash_image_url', ''),
            'splash_duration_ms' => AppSetting::get('splash_duration_ms', 2000),
            'onboarding_enabled' => AppSetting::get('onboarding_enabled', true),
        ]);
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('General')
                    ->description('Basic app configuration')
                    ->schema([
                        Forms\Components\TextInput::make('app_name')
                            ->label('App Name')
                            ->required(),
                        Forms\Components\TextInput::make('app_tagline')
                            ->label('App Tagline'),
                    ])->columns(2),

                Forms\Components\Section::make('Version Control')
                    ->description('Manage app versions and force updates')
                    ->schema([
                        Forms\Components\TextInput::make('app_version')
                            ->label('Current Version')
                            ->required()
                            ->helperText('Latest app version available'),
                        Forms\Components\TextInput::make('min_app_version')
                            ->label('Minimum Required Version')
                            ->required()
                            ->helperText('Users below this version will be forced to update'),
                    ])->columns(2),

                Forms\Components\Section::make('Maintenance Mode')
                    ->schema([
                        Forms\Components\Toggle::make('maintenance_mode')
                            ->label('Enable Maintenance Mode')
                            ->helperText('When enabled, users will see maintenance message'),
                        Forms\Components\Textarea::make('maintenance_message')
                            ->label('Maintenance Message')
                            ->rows(2),
                    ]),

                Forms\Components\Section::make('Splash & Onboarding')
                    ->schema([
                        Forms\Components\TextInput::make('splash_image_url')
                            ->label('Custom Splash Image URL')
                            ->url()
                            ->helperText('Leave empty for default'),
                        Forms\Components\TextInput::make('splash_duration_ms')
                            ->label('Splash Duration (ms)')
                            ->numeric()
                            ->default(2000),
                        Forms\Components\Toggle::make('onboarding_enabled')
                            ->label('Show Onboarding for New Users'),
                    ])->columns(2),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        $data = $this->form->getState();

        foreach ($data as $key => $value) {
            AppSetting::set($key, $value, 'app');
        }

        Notification::make()
            ->title('Settings saved successfully')
            ->success()
            ->send();
    }

    protected function getFormActions(): array
    {
        return [
            Action::make('save')
                ->label('Save Changes')
                ->submit('save'),
        ];
    }
}
