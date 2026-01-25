<?php

namespace App\Filament\Pages;

use App\Models\AppSetting;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Pages\Page;
use Filament\Notifications\Notification;

class BrandingSettings extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-paint-brush';
    protected static ?string $navigationGroup = 'Settings';
    protected static ?string $navigationLabel = 'Branding';
    protected static ?int $navigationSort = 6;
    protected static string $view = 'filament.pages.settings-page';

    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill([
            'primary_color' => AppSetting::get('primary_color', '#0047C1'),
            'secondary_color' => AppSetting::get('secondary_color', '#C1272D'),
            'logo_url' => AppSetting::get('logo_url', ''),
            'icon_url' => AppSetting::get('icon_url', ''),
        ]);
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Brand Colors')
                    ->description('Define your brand color palette')
                    ->schema([
                        Forms\Components\ColorPicker::make('primary_color')
                            ->label('Primary Color')
                            ->helperText('Main brand color (buttons, links, navigation)'),
                        Forms\Components\ColorPicker::make('secondary_color')
                            ->label('Secondary Color')
                            ->helperText('Accent color (call-to-action, highlights)'),
                    ])->columns(2),

                Forms\Components\Section::make('Logo & Icons')
                    ->schema([
                        Forms\Components\TextInput::make('logo_url')
                            ->label('Logo URL')
                            ->url()
                            ->placeholder('https://example.com/logo.png')
                            ->helperText('Full logo for light backgrounds'),
                        Forms\Components\TextInput::make('icon_url')
                            ->label('App Icon URL')
                            ->url()
                            ->placeholder('https://example.com/icon.png')
                            ->helperText('Square app icon'),
                    ])->columns(2),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        $data = $this->form->getState();

        foreach ($data as $key => $value) {
            AppSetting::set($key, $value, 'branding');
        }

        Notification::make()
            ->title('Branding settings saved')
            ->success()
            ->send();
    }
}
