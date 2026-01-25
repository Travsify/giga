<?php

namespace App\Filament\Pages;

use App\Models\AppSetting;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Pages\Page;
use Filament\Notifications\Notification;

class ContentSettings extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-document-text';
    protected static ?string $navigationGroup = 'Settings';
    protected static ?string $navigationLabel = 'Content & Legal';
    protected static ?int $navigationSort = 5;
    protected static string $view = 'filament.pages.settings-page';

    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill([
            'terms_url' => AppSetting::get('terms_url', ''),
            'privacy_url' => AppSetting::get('privacy_url', ''),
            'support_email' => AppSetting::get('support_email', ''),
            'support_phone' => AppSetting::get('support_phone', ''),
            'about_us' => AppSetting::get('about_us', ''),
        ]);
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Legal Documents')
                    ->schema([
                        Forms\Components\TextInput::make('terms_url')
                            ->label('Terms & Conditions URL')
                            ->url()
                            ->placeholder('https://giga.com/terms'),
                        Forms\Components\TextInput::make('privacy_url')
                            ->label('Privacy Policy URL')
                            ->url()
                            ->placeholder('https://giga.com/privacy'),
                    ])->columns(2),

                Forms\Components\Section::make('Support Contact')
                    ->schema([
                        Forms\Components\TextInput::make('support_email')
                            ->label('Support Email')
                            ->email()
                            ->placeholder('support@giga.com'),
                        Forms\Components\TextInput::make('support_phone')
                            ->label('Support Phone')
                            ->tel()
                            ->placeholder('+44 123 456 7890'),
                    ])->columns(2),

                Forms\Components\Section::make('About')
                    ->schema([
                        Forms\Components\Textarea::make('about_us')
                            ->label('About Us')
                            ->rows(4)
                            ->helperText('Company description shown in the app'),
                    ]),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        $data = $this->form->getState();

        foreach ($data as $key => $value) {
            AppSetting::set($key, $value, 'content');
        }

        Notification::make()
            ->title('Content settings saved')
            ->success()
            ->send();
    }
}
