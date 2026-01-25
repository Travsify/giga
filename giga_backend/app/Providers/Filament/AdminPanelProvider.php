<?php

namespace App\Providers\Filament;

use Filament\Http\Middleware\Authenticate;
use Filament\Http\Middleware\DisableBladeIconComponents;
use Filament\Http\Middleware\DispatchServingFilamentEvent;
use Filament\Pages;
use Filament\Panel;
use Filament\PanelProvider;
use Filament\Support\Colors\Color;
use Filament\Widgets;
use Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse;
use Illuminate\Cookie\Middleware\EncryptCookies;
use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken;
use Illuminate\Routing\Middleware\SubstituteBindings;
use Illuminate\Session\Middleware\AuthenticateSession;
use Illuminate\Session\Middleware\StartSession;
use Illuminate\View\Middleware\ShareErrorsFromSession;

class AdminPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
        return $panel
            ->default()
            ->id('admin')
            ->path('admin')
            ->login()
            ->brandName('Giga Command Center')
            ->darkMode(true)
            ->colors([
                'primary' => [
                    50 => '235, 241, 255',
                    100 => '214, 227, 255',
                    200 => '173, 199, 255',
                    300 => '128, 168, 255',
                    400 => '77, 131, 230',
                    500 => '0, 71, 193',    // #0047C1 - Giga Primary Blue
                    600 => '0, 56, 153',
                    700 => '20, 48, 117',   // #143075 - Dark Blue
                    800 => '15, 36, 88',
                    900 => '10, 24, 59',
                    950 => '5, 12, 30',
                ],
                'danger' => [
                    50 => '255, 241, 241',
                    100 => '255, 224, 224',
                    200 => '255, 189, 189',
                    300 => '255, 143, 143',
                    400 => '230, 77, 82',
                    500 => '193, 39, 45',   // #C1272D - Giga Red
                    600 => '153, 31, 35',
                    700 => '117, 24, 27',
                    800 => '88, 18, 20',
                    900 => '59, 12, 13',
                    950 => '30, 6, 7',
                ],
                'success' => [
                    50 => '236, 253, 245',
                    100 => '209, 250, 229',
                    200 => '167, 243, 208',
                    300 => '110, 231, 183',
                    400 => '52, 211, 153',
                    500 => '34, 197, 94',   // #22C55E - Success Green
                    600 => '22, 163, 74',
                    700 => '21, 128, 61',
                    800 => '22, 101, 52',
                    900 => '20, 83, 45',
                    950 => '5, 46, 22',
                ],
            ])
            ->font('Outfit')
            ->discoverResources(in: app_path('Filament/Resources'), for: 'App\\Filament\\Resources')
            ->discoverPages(in: app_path('Filament/Pages'), for: 'App\\Filament\\Pages')
            ->pages([
                Pages\Dashboard::class,
            ])
            ->discoverWidgets(in: app_path('Filament/Widgets'), for: 'App\\Filament\\Widgets')
            ->widgets([
                Widgets\AccountWidget::class,
            ])
            ->middleware([
                EncryptCookies::class,
                AddQueuedCookiesToResponse::class,
                StartSession::class,
                AuthenticateSession::class,
                ShareErrorsFromSession::class,
                VerifyCsrfToken::class,
                SubstituteBindings::class,
                DisableBladeIconComponents::class,
                DispatchServingFilamentEvent::class,
            ])
            ->authMiddleware([
                Authenticate::class,
            ]);
    }
}
