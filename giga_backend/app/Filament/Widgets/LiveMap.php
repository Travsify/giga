<?php

namespace App\Filament\Widgets;

use Filament\Widgets\Widget;

class LiveMap extends Widget
{
    protected static string $view = 'filament.widgets.live-map';
    
    protected int | string | array $columnSpan = 'full';
}
