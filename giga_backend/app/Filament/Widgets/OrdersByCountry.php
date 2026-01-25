<?php

namespace App\Filament\Widgets;

use Filament\Widgets\Widget;

class OrdersByCountry extends Widget
{
    protected static ?int $sort = 5;
    
    protected int | string | array $columnSpan = 1;

    protected static string $view = 'filament.widgets.orders-by-country';
}
